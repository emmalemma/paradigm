#views go here
this.Users =
	_id: "_design/users"
	views:
		by_sessid:
			map: (doc)-> emit(doc.sessid, null)
			
		by_email:
			map: (doc)-> emit(doc.email, null)