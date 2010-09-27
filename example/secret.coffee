#functions executed on server go here

@$get_current_user =->
	@Users.by_sessid {key:@_sessid}, (err, doc)=>
												if doc 
													if doc.rows.length > 0
														@respond doc.rows[0].id
													else
														@respond null
												else
													console.log "Err:#{err}"
						
@$validate_user_email =(email_string)->
	if not ematch = email_string.match(/\b[A-Z0-9._%-]+@[A-Z0-9.-]+\.[A-Z]{2,4}\b/i)
		return @respond {flash:"Invalid email address."}
	email = ematch[0]
	@Users.getDoc email, (err, email_doc) =>
		if err
			@respond {flash:"Ok!"}
		else
			@respond {flash:"That email is already taken."}
			
@$save_new_user =(params)->
	doc =
		_id: params.email
		sessid: @_sessid
	
	for key in params
		if key in ['facts']
			doc[key] = params[key]
			
	@Users.saveDoc params.email, doc, (err, email_doc) =>
		if err
			console.log err
			@respond {"error": "That email is already taken."}
		else
			@respond {"success": "Account registered."}
		