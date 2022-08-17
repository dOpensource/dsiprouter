
route[STIRSHAKEN_INBOUND] {
  	 # Only route if request is coming from an Endpoint
    if (!allow_source_address(FLT_CARRIER)) {
            xlog("L_INFO", "[STIRSHAKEN_INBOUND] <$ci> $si not allowed to talk with this server \n");
            return;
    }

    xlog("L_INFO", "STIR/SHAKEN Inbound Logic");

	#Verify Call Identity

    xlog("L_INFO", "Identity Header: $hdr(Identity),$hdr(Reason)");
    xlog("L_INFO", "Encoded Header 1:   $(hdr(Identity){s.select,0,.})");
    xlog("L_INFO", "Encoded Header 2:   $(hdr(Identity){s.select,1,.})");
    xlog("L_INFO", "Decoded Header 1:   $(hdr(Identity){s.select,0,.}{s.decode.base64}) ");
    xlog("L_INFO", "Decoded Header 2:   $(hdr(Identity){s.select,1,.}{s.decode.base64}) ");

    $var(json_payload) = $(hdr(Identity){s.select,1,.}{s.decode.base64});
    jansson_get_field($var(json_payload), "attest", "$var(attest_value)" );
    xlog("L_INFO", "Attest Value:   $(var(attest_value)) ");

	if (1 == stirshaken_check_identity()) {
	    xlog("L_INFO", "Shaken Identity is OK\n");

	    if ( $var(attest_value) == "A"){
            uac_replace_from("$sel(cfg_get.stir_shaken.stir_shaken_prefix_a)  $fU","");
	    }
	    else if ( $var(attest_value) == "B"){
            uac_replace_from("$sel(cfg_get.stir_shaken.stir_shaken_prefix_b)  $fU","");
	    }
	    else if ( $var(attest_value) == "C"){
            uac_replace_from("$sel(cfg_get.stir_shaken.stir_shaken_prefix_c)  $fU","");
	    }
	    else{
            uac_replace_from("VERIFIED  $fU","");
	    }
    } else {
        xlog("L_INFO", "Shaken Identity is invalid\n");
        uac_replace_from("$sel(cfg_get.stir_shaken.stir_shaken_prefix_invalid)  $fU","");
    }

}

route[STIRSHAKEN_OUTBOUND] {

    xlog("L_INFO", "[STIRSHAKEN_OUTBOUND] In the STIRSHAKEN_OUTBOUND logic.  \n");
  	
	# Only route if request is coming from an Endpoint
	# and is an INVITE

	if (allow_source_address(FLT_CARRIER)) {
        xlog("L_INFO", "[STIRSHAKEN_OUTBOUND] <$ci> $si This is a carrier ignoring \n");
		return;
	}
       
	if (!is_method("INVITE")) {
	    xlog("L_INFO", "[STIRSHAKEN_OUTBOUND] This is a invite message, ignoring. \n");
		return;		
	}
			

    xlog("L_INFO", "STIRSHAKEN Outbound Logic - method: $rm");

	# get the outbound caller id number
    $var(caller_from_number) = $fU;

    # Check if the number exist in the dr_rules htable
    #if ($sht(dr_rules=>$var(caller_from_number))){
        if (1 == stirshaken_add_identity($sel(cfg_get.stir_shaken.stir_shaken_cert_url ), "A", $fU, $rU, "" , $sel(cfg_get.stir_shaken.stir_shaken_key_path ) )) {
			xlog("L_INFO", "Shaken authentication added (SIP Identity Header created)\n");
		} else {
			xlog("L_INFO", "Failed to add identity\n");
		}
    #}

}


