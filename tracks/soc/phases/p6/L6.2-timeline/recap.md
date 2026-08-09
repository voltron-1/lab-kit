Normalize every timestamp to UTC before you order anything — local syslog has no year or offset, Windows and ECS are already UTC.
Order by occurrence (@timestamp), never by arrival (event.ingested) — ingestion lag scrambles the sequence.
The timeline is the spine of the escalation; get the order right and the story tells itself.
