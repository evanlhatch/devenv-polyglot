# Next steps

create gneral connections manager using pydantic settings + unfieid factory
https://www.kimi.com/chat/19b88134-af52-8b76-8000-098c22a9e36e

copier should handle all scaffolding like this

# Secrets

secret management revolves around user being logged into infisical in the correct project and then it automatically hydrating env variables in ram (not dotenv). it automatically connects to my inifisical project via .infisical.json and `infisical init` should be used if this is brokn

## deprecated

I am changing to have this be opinionated around secretspec. It will automatically search the provider (currently 1password) and populate RAM with the desired env variables.

this should achieve the effect of automatically doing "infisical run/secretspec run" without having to invoke them, and means nothign is kept in dotenv or by extension the nix store

if a new secret is adde don the backend provider leaving and reintering the shell should refind it. as long as the individual secrets' name is truly unique it shoudl find it without needing to know what 1pass vault its in.

infisical should be used for production via the kube operator which itself should be populated via it's native integration with 1pass service account. so i touch onepass then it hydrates infisical with secrets to use in kube

#NOTE I AM ABANDONING IT AS IT CANNOT LOOK AT FIELDS meaning id have to remake the secrets and keep it a simple key value
