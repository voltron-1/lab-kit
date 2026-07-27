#!/bin/bash
# TEACHING SAMPLE — deliberately flawed. Never run this.
# It exists to be read and reviewed, not executed.
# Deploy helper - fetches the latest agent build and installs it. So easy!

URL=https://releases.agent-updates.test/latest/agent.tar.gz
DEST=/opt/agent

# Download to a temp location
curl -s $URL -o /tmp/agent.tar.gz

# Unpack over the install directory
tar -xzf /tmp/agent.tar.gz -C $DEST

# Restart to pick up the new version
systemctl restart agent
echo "Deployed the latest agent!"
