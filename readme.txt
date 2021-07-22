# Running the actions runners

In order to start the actions runner, run the following:
GITHUB_PAT="XXX" ./start.sh

The PAT (Personal Access Token) should have the rights to register Actions Runner in the dxos organization.

# Stopping the runners

docker-compose down

Be patient, because the runners de-register themselves at that point, it can take a moment.

