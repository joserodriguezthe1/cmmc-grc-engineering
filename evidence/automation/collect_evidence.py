#!/usr/bin/env python3
"""
CMMC L2 evidence collector.

Snapshots live AWS configuration that demonstrates control implementation, and
writes timestamped JSON artifacts into evidence/collected/. This is the
"evidence as code" layer (supports CA.L2-3.12.1 / AU.L2-3.3.1).

Each collector is small, read-only, and degrades gracefully if a service is not
enabled (e.g. Config/GuardDuty off for Free-Tier reasons) so the script always
produces a partial evidence package rather than failing.

Usage:
    python evidence/automation/collect_evidence.py [--region us-east-1]

Requires: boto3, configured AWS credentials with read-only access.
"""
import argparse
import datetime as dt
import json
import os
import sys

try:
    import boto3
    from botocore.exceptions import ClientError, BotoCoreError
except ImportError:
    sys.exit("boto3 is required:  pip install boto3")

OUT_DIR = os.path.join(os.path.dirname(__file__), "..", "collected")


def _safe(fn):
    """Run a collector, capturing errors as evidence rather than crashing."""
    try:
        return {"ok": True, "data": fn()}
    except (ClientError, BotoCoreError) as e:
        return {"ok": False, "error": str(e)}


def collect_account(session):
    sts = session.client("sts")
    return _safe(lambda: sts.get_caller_identity())


def collect_password_policy(session):
    iam = session.client("iam")
    # IA.L2-3.5.7 / 3.5.8
    return _safe(lambda: iam.get_account_password_policy().get("PasswordPolicy", {}))


def collect_mfa_summary(session):
    iam = session.client("iam")

    def _run():
        report = iam.generate_credential_report  # noqa: F841
        users = iam.list_users().get("Users", [])
        result = []
        for u in users:
            devices = iam.list_mfa_devices(UserName=u["UserName"]).get("MFADevices", [])
            result.append({"user": u["UserName"], "mfa_devices": len(devices)})
        return result  # IA.L2-3.5.3

    return _safe(_run)


def collect_cloudtrail(session):
    ct = session.client("cloudtrail")
    # AU.L2-3.3.1 / 3.3.2 / 3.3.8
    return _safe(lambda: ct.describe_trails().get("trailList", []))


def collect_s3_public_access(session):
    s3 = session.client("s3")

    def _run():
        buckets = s3.list_buckets().get("Buckets", [])
        out = []
        for b in buckets:
            name = b["Name"]
            entry = {"bucket": name}
            try:
                pab = s3.get_public_access_block(Bucket=name)
                entry["public_access_block"] = pab["PublicAccessBlockConfiguration"]
            except ClientError:
                entry["public_access_block"] = None  # AC.L2-3.1.22 gap signal
            try:
                enc = s3.get_bucket_encryption(Bucket=name)
                entry["encryption"] = enc["ServerSideEncryptionConfiguration"]
            except ClientError:
                entry["encryption"] = None  # SC.L2-3.13.16 gap signal
            out.append(entry)
        return out

    return _safe(_run)


def collect_config_compliance(session):
    cfg = session.client("config")
    # CA.L2-3.12.3 — only present if Config is enabled
    return _safe(lambda: cfg.describe_compliance_by_config_rule().get("ComplianceByConfigRules", []))


def collect_guardduty(session):
    gd = session.client("guardduty")
    # SI.L2-3.14.6 / 3.14.7 — only present if GuardDuty is enabled
    return _safe(lambda: gd.list_detectors().get("DetectorIds", []))


COLLECTORS = {
    "account": collect_account,
    "iam_password_policy": collect_password_policy,
    "iam_mfa": collect_mfa_summary,
    "cloudtrail": collect_cloudtrail,
    "s3_public_access_and_encryption": collect_s3_public_access,
    "aws_config_compliance": collect_config_compliance,
    "guardduty": collect_guardduty,
}


def main():
    parser = argparse.ArgumentParser(description="Collect CMMC L2 evidence from AWS")
    parser.add_argument("--region", default=os.environ.get("AWS_REGION", "us-east-1"))
    parser.add_argument("--profile", default=os.environ.get("AWS_PROFILE"))
    args = parser.parse_args()

    session = boto3.Session(region_name=args.region, profile_name=args.profile)

    timestamp = dt.datetime.now(dt.timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    package = {
        "collected_at": timestamp,
        "region": args.region,
        "framework": "CMMC Level 2",
        "evidence": {name: fn(session) for name, fn in COLLECTORS.items()},
    }

    os.makedirs(OUT_DIR, exist_ok=True)
    out_path = os.path.join(OUT_DIR, f"evidence-{timestamp}.json")
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(package, f, indent=2, default=str)

    # Console summary
    print(f"Evidence written to {out_path}\n")
    for name, result in package["evidence"].items():
        status = "OK " if result.get("ok") else "ERR"
        print(f"  [{status}] {name}")

    print("\nReminder: collected/ is gitignored — it may contain account IDs/ARNs.")


if __name__ == "__main__":
    main()
