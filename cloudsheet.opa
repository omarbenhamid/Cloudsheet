//import stdlib.core.xhtml

type celltype = {value:string}
type rowtype = {cells:intmap(celltype)}
type page = {rows:intmap(rowtype)}
type sheet = {pages:stringmap(page)}

type msgtype = {valueupdate} / {cursorfocus}
type message = {updatetype:msgtype row:int col:int newvalue:option(string)}

db /cloudsheet/sheets : stringmap(sheet)

clouds = Mutable.make([] : list((string,Network.network(message))))

select_cell(sheetname, row,col) = (
	Network.broadcast({updatetype={cursorfocus} row=row col=col newvalue={none}}, getcloud(sheetname))
)

keyboard_navigate(evt:Dom.event, sheetname, from_row, from_col) = (
	if evt.key_code == {some=Dom.Key.RIGHT} then 
		select_cell(sheetname, from_row, from_col+1)
	else if evt.key_code ==  {some=Dom.Key.LEFT} then 
		select_cell(sheetname, from_row, from_col-1)
	else if evt.key_code ==  {some=Dom.Key.UP} then 
		select_cell(sheetname, from_row-1, from_col)
	else if evt.key_code ==  {some=Dom.Key.DOWN} || evt.key_code ==  {some=Dom.Key.RETURN} then 
		select_cell(sheetname, from_row+1, from_col)		
	//void
)

// This is a cloud sheet
//Show a cell
showcell(sheetname,row,col):xhtml = (
<td><input id="cell-R{row}C{col}" onkeydown={evt->keyboard_navigate(evt,sheetname,row,col)} type="text" value="{/cloudsheet/sheets[sheetname]/pages["default"]/rows[row]/cells[col]/value}"/></td>
)

//Show a hole row
showrow(sheetname,row) = (
	<tr>
	{
	for({col=1 trow=<></>},
		(~{col trow} -> {col=col+1 trow=<>{trow} {showcell(sheetname,row,col)}</>}),
		(~{col ...} -> col <= 10)).trow
	}
	</tr>

)
execute_update(msg:message) = (
	do println("Received cloud mesasge {Debug.dump(msg)}")
	match msg
		| {updatetype={cursorfocus} ~row ~col ...} -> Dom.give_focus(#{"cell-R{row}C{col}"})
		//| {updatetype={valueupdate} newvalue={some=newval} ~row ~col ...}-> Dom.set_text(#{"cell-R{row}C{col}"},newval)
		| any -> println("Error : bad message ? {Debug.dump(any)}")
)

getcloud(name) = (
	match List.assoc(name,clouds.get())
		| {none} -> 
			newcloud = Network.cloud(name) : Network.network(message)
			do clouds.set((name, newcloud) +> clouds.get())
			newcloud
		| {some=thecloud} -> thecloud
)
//Show the spreadsheet
showsheet(sheetname)=(
	<h1>{sheetname}</h1>
	<table onready={_->Network.add_callback(execute_update,getcloud(sheetname))}>
	{
	for({row=1 table=<></>},
		(~{row table} -> {row=row+1 table=<>{table} {showrow(sheetname,row)}</>}),
		(~{row ...} -> row <= 10)).table
	}
	</table>
)

server = one_page_server("Hello", -> showsheet("somesheet"))