route[TRANSNEXUS_OUTBOUND] {
  	 # Only route if request is coming from an Endpoint
        if (!allow_source_address(FLT_PBX)) {
                xlog("L_INFO", "[TRANSNEXUS_OUTBOUND] <$ci> $si not allowed to talk with Transnexus \n");
                return;
        }
	
      	xlog("L_INFO", "Transnexus Outbound Logic");
	
	#Store the $ru that was selected
	$avp(dr_current_ruri) = $ru;

	#Send call to clearip server
	$ru = "sip:" + $rU + "@" + $sel(cfg_get.transnexus.authservice_host) + ";transport=tcp";

	#Set a failure route to get the 302
	if (is_method("INVITE")) {
		t_on_reply("TRANSNEXUS_OUTBOUND_REPLY");
                t_on_failure("TRANSNEXUS_OUTBOUND_FAILURE");
        }


}

failure_route[TRANSNEXUS_OUTBOUND_FAILURE] {


	if (t_check_status("302|403|503")) {	
		xlog("L_INFO", "Transnexus Outbound Failure Logic");
        	#Send call to Carrier
		#$ru = "sip:" + $rU + "@" + "206.147.88.37" + ":" + "5060;transport=UDP";
		$ru = $avp(dr_current_ruri);
		#Append Identity Header
		if $avp(Identity) != ""
			append_hf("Identity: $avp(Identity)\r\n");
		#Send call outbound
		t_relay();
		exit;
	}
}

onreply_route[TRANSNEXUS_OUTBOUND_REPLY] {

	if (t_check_status("302|403|503")) {	
		#Get Identity header and append it to header.  Look for Identity or X-Identity
		if ($hdr(Identity) != "") 
			$avp(Identity) = $hdr(Identity);
		else if ($hdr(X-Identity) != "")
			$avp(Identity) = $hdr(X-Identity);
		
		if ($avp(Identity) != "")
			xlog("L_INFO", "Identity Header Found: $avp(Identity),$hdr(Reason)");
		else
			xlog("L_INFO", "Identity Header Not Found");
	}
}




route[TRANSNEXUS_INBOUND] {
  	 # Only route if request is coming from an Endpoint
        if (!allow_source_address(FLT_CARRIER)) {
                xlog("L_INFO", "[TRANSNEXUS_INBOUND] <$ci> $si not allowed to talk with Transnexus \n");
                return;
        }
	
      	xlog("L_INFO", "Transnexus Inbound Logic");
	
	#Send call to clearip server
	$ru = "sip:" + $rU + "@" + "inbound.sip.clearip.com" + ":" + "5060;transport=tcp";

	#Set a failure route to get the 302
	if (is_method("INVITE")) {
		t_on_reply("TRANSNEXUS_INBOUND_REPLY");
                t_on_failure("TRANSNEXUS_INBOUND_FAILURE");
        }

}

onreply_route[TRANSNEXUS_INBOUND_REPLY] {

	if (t_check_status("302")) {	
		#Get Identity header and append it to header
		xlog("L_INFO", "Identity Header: $hdr(Identity),$hdr(Reason)");
		exit;
	}
}

failure_route[TRANSNEXUS_INBOUND_FAILURE] {

	
	if (t_check_status("302")) {	
		
		xlog("L_INFO", "Transnexus Inbound Failure Logic");
		# Route back to freeswitch or just call NumberSentry API from here
		t_drop_replies();
		send_reply("100", "Trying");
		exit;
	}
}
