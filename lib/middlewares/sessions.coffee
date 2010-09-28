#TODO: this should be different
generate_session =()->
	Math.random().toString(36)
	
@initialize=()->
	@route '$get_sessid' , -> @Session.id

@before_every_request =()->
	@Session =
		id: @Request.getCookie("_sessid")
		
	if not @Session.id 		#or validate session, etc...
		@log "Generating session..."
		@Session.id = generate_session()
		@Response.setCookie("_sessid", @Session.id)
		
@ClientSide =->
	@Session = new Element('div', "id":Cookie.read('_sessid'))
	console.log "Session: #{@Session.id}"