route[STIRSHAKEN_OUTBOUND] {
  	
	# Only route if request is coming from an Endpoint
	# and is an INVITE

	if (allow_source_address(FLT_CARRIER)) {
		return;

	}
       
	if (!is_method("INVITE")) {
		return;		
	}
			
	
    xlog("L_INFO", "STIRSHAKEN Outbound Logic - method: $rm");
	
	#Store the $ru that was selected
	$avp(dr_current_ruri) = $ru;

	#Send call to clearip server
	$ru = "sip:" + $rU + "@" + $sel(cfg_get.transnexus.authservice_host) + ";transport=tcp";
	$du = $ru;

	#Set a failure route to get the 302
	if (is_method("INVITE")) {
		t_on_reply("STIRSHAKEN_OUTBOUND_REPLY");
                t_on_failure("STIRSHAKEN_OUTBOUND_FAILURE");
        }
	

}

failure_route[STIRSHAKEN_OUTBOUND_FAILURE] {


	if (t_check_status("302|403|503")) {	
		xlog("L_INFO", "STIR/SHAKEN Outbound Failure Logic");
		
		#Append Identity Header
		if $avp(Identity) != ""
			append_hf("Identity: $avp(Identity)\r\n");
	
		#Check if contact contains
		if($hdr(Contact)=~"clearip.com") {

			#Send call outbound using dSIPRouter Routes
			$ru = $avp(dr_current_ruri);
			$du = $ru;
			t_relay();
		}
		else {
			#Remove the main branch
			$ru = $null;

			#Get Redirects from STIR/SHAKEN
			get_redirects("*");
			#Route to redirects
			t_relay();
		}
	}	
}


onreply_route[STIRSHAKEN_OUTBOUND_REPLY] {

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


	if (is_method("BYE")) {
		xlog("L_INFO", "*******STIRSHAKEN_OUTBOUND_REPLY BYE*******");
	}

}

onreply_route[STIRSHAKEN_CARRIER_REPLY] {
	xlog("L_INFO", "*******STIRSHAKEN_CARRIER_REPLY*******");
}


route[STIRSHAKEN_INBOUND] {
  	 # Only route if request is coming from an Endpoint
    if (!allow_source_address(FLT_CARRIER)) {
            xlog("L_INFO", "[STIRSHAKEN_INBOUND] <$ci> $si not allowed to talk with this server \n");
            return;
    }

    xlog("L_INFO", "STIR/SHAKEN Inbound Logic");

	#Verify Call Identity

    xlog("L_INFO", "Identity Header: $hdr(Identity),$hdr(Reason)");

	if (1 == stirshaken_check_identity()) {
        xlog("L_INFO", "Shaken Identity is OK\n");
    } else {
        xlog("L_INFO", "Shaken Identity is invalid\n");
    }

	#Set a failure route to get the 302
	if (is_method("INVITE")) {
		t_on_reply("STIRSHAKEN_INBOUND_REPLY");
                t_on_failure("STIRSHAKEN_INBOUND_FAILURE");
        }
}


route[]

onreply_route[STIRSHAKEN_INBOUND_REPLY] {

	if (t_check_status("302")) {	
		#Get Identity header and append it to header
		xlog("L_INFO", "Identity Header: $hdr(Identity),$hdr(Reason)");
		exit;
	}
}

failure_route[STIRSHAKEN_INBOUND_FAILURE] {
	if (t_check_status("302")) {
		xlog("L_INFO", "STIR/SHAKEN Inbound Failure Logic");
		# Route back to freeswitch or just call NumberSentry API from here
		t_drop_replies();
		send_reply("100", "Trying");
		exit;
	}
}
