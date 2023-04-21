output "endpoint_url" {
  value = "${aws_api_gateway_stage.BR_loggroup.invoke_url}"
}