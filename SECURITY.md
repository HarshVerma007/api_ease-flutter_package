# Security Policy

## Supported versions

Only the latest published version of api_ease receives security fixes.

## Reporting a vulnerability

Please **do not** report security issues in public issues or pull requests.

Use GitHub's private reporting instead: open the repository's **Security** tab and choose **Report a vulnerability**. Include a description, steps to reproduce and the affected version.

You can expect an initial response within 7 days. Once a fix is released, the issue will be disclosed in the changelog.

## Scope notes

api_ease sends `HEAD` requests to the endpoints listed in `ConnectivityConfig.endpoints` (by default `https://clients3.google.com/generate_204`) to verify connectivity. No user data is sent. If your app's privacy policy or network rules require it, point the probe at an endpoint you control.
