/*
 * mod_dsiprouter.c
 */
/*!
 * \file
 * \brief dSipRouter Module Interface
 * \ingroup dsiprouter
 * Module: \ref dsiprouter
 */

/**
 * @defgroup dsiprouter dsiprouter :: Kamailio dsiprouter module
 * @brief Kamailio dsiprouter module
 */

#include <string.h>
#include <stdio.h>

#include "../../core/ver_defs.h"
#include "../../core/sr_module.h"
#include "../../core/mod_fix.h"
#include "../../core/rpc.h"
#include "../../core/rpc_lookup.h"

#include "mod_funcs.h"

MODULE_VERSION

/* module params */
static char *license_file = "/etc/dsiprouter/license.txt";
static char *signature_file = "/etc/dsiprouter/license-sig.b64";
static char *uuid_file = "/etc/dsiprouter/uuid.txt";

/* Module management function prototypes */
static int mod_init(void);
static int mod_child_init(int rank);
static void mod_destroy(void);
static int fixup_get_params(void **param, int param_no);
static int fixup_get_params_free(void **param, int param_no);
static int mod_health_check();
static void rpc_health_check(rpc_t *rpc, void *ctx);

/* Exported functions */
static cmd_export_t cmds[] = {
	{"health_check", (cmd_function) mod_health_check, 1,
	fixup_get_params, fixup_get_params_free, ANY_ROUTE},
	{0,0,                                             0,0,0}
};

/* Exported rpc functions */
static const char *rpc_health_check_doc[2] = {"Check health of dsiprouter system.", 0};
static rpc_export_t rpc_cmds[] = {
		{"dsiprouter.health_check", rpc_health_check, rpc_health_check_doc,0},
		{0,0,0,0}
};

/* Exported parameters */
static param_export_t params[] = {
		{"license_file", PARAM_STRING, &license_file},
		{"signature_file", PARAM_STRING, &signature_file},
		{"uuid_file", PARAM_STRING, &uuid_file},
		{0,0,0}
};

/* Module interface */
module_exports_t exports = {
		"dsiprouter", /* module name */
		DEFAULT_DLFLAGS, 	/* dlopen flags */
		cmds,      			/* exported functions */
		params,    			/* exported parameters */
		0,   		/* exported rpc functions */
		0,        	/* exported pseudo-variables */
		0,        /* exported response function */
		mod_init,        	/* exported initialization function */
		mod_child_init,		/* exported child initialization function */
		mod_destroy,   		/* exported destroy function */
};

/* Module initialization function - The main initialization function will be called
   before any other function exported by the module. The function will be called only once,
   before the main process forks. This function is good for initialization that is common
   for all the children (processes). The function should return 0 if everything went OK
   and a negative error code otherwise. Server will abort if the function returns a negative value.
*/
static int mod_init(void) {
	LM_DBG("mod_dsiprouter initializing\n");
	if (rpc_register_array(rpc_cmds) != 0) {
		LM_ERR("failed to register RPC commands\n");
		return -1;
	}
	return 0;
}

static int mod_child_init(int rank) {
	return 0;
}

static void mod_destroy(void) {
	LM_DBG("mod_dsiprouter unloading\n");
}

static int fixup_get_params(void **param, int param_no) {
	if (param_no == 1) {
		return fixup_pvar_null(param, 1);
	}
	LM_ERR("invalid parameter number <%d>\n", param_no);
	return -1;
}

static int fixup_get_params_free(void **param, int param_no) {
	if (param_no == 1) {
		return fixup_free_pvar_null(param, 1);
	}
	LM_ERR("invalid parameter number <%d>\n", param_no);
	return -1;
}

static int mod_health_check() {
	return validate_license(license_file, signature_file, uuid_file);
}

static void rpc_health_check(rpc_t *rpc, void *ctx) {
	if (!validate_license(license_file, signature_file, uuid_file)) {
		rpc->fault(ctx, 500, "Health Check Failed");
	}
	else {
		rpc->rpl_printf(ctx, "Health Check Succeeded");
	}
}
