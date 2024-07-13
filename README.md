export AWS_DEFAULT_PROFILE=sydney

Terrafrom code to connect aws security hub with aws event bridget and trigger lambda.


Lambda uses aws bedrock to generate a report.


To Run

sh 2-build-layer.sh

terraform init 

terraform apply

sh 4-invoketf.sh


to increase no of issues it picks from security hub can change variable     max_finding = 2  in function/lambda_function.py