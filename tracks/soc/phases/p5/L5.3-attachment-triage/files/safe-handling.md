# Safe Handling of Attachments
- Never open or execute suspicious attachments.
- Inspect magic bytes using `file` or `xxd | head`.
- Compute file identity using `sha256sum`.
- .docm and .xlsm files carry macro risk (vbaProject).
