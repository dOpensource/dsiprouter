contract Addressbook {

mapping (string => string) URIs;



function Addressbook() {


//string key;

//key  = "5554443333";
//URIs[key] = "sip:proxy.detroitpbx.com:5060";

}


function add(string _number, string _uri) {
	URIs[_number] = _uri;

} 

function lookup(string _number) constant returns (string) {

	return URIs[_number];
}



}
 
