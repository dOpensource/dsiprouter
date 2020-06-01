$("#domain").keyup(function () {
	value = document.getElementById("domain").value;
	console.log(value);
	if (value.includes("*")) {

		command = "dsiprouter generatecert ";
		$("#terminalCommand").text(command + value);
		$("#terminalDiv").removeClass("hide");
	}
	else {

		$("#terminalDiv").addClass("hide");
	}

})

$("#certtype_generate").change(function () {

	$("#generate").removeClass("hide");
	$("#upload").addClass("hide");
})

$("#certtype_upload").change(function () {

	$("#generate").addClass("hide");
	$("#upload").removeClass("hide");
})


$(".close").click(function () {

	
	document.getElementById("domain").value = "";
	$("#terminalDiv").addClass("hide");
	$("#terminalCommand").text("");
	$("#certtype_generate").prop('selected', true);

})
