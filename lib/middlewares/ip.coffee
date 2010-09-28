
@before_every_request =()->
	@Request.ip = req.connection.remoteAddress