
@before_request =()->
	@Request.ip = req.connection.remoteAddress