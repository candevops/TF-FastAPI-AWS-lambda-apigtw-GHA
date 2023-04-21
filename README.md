# TF-FastAPI-AWS-lambda-apigtw-GHA
1- I opt for Lambda with API since it’s scalable and cost effective. You don’t need to create any server etc.
2- In order to integrate FastAPI with I used Magnum package.
3-I also added logging to be able to monitor. Since APIs running in a short time interval and there maybe many request can be sent to the end point and it may be hard to capture errors and other issues.
4-this is a POC to show implementation capabilities with time constraint. if I had time I would integrate with Vault not to keep any secrets as env var and create dynamic short lived secrets and keys for AWS.
