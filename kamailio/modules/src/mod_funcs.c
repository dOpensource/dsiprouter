#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdbool.h>
#include <time.h>
#include <openssl/pem.h>

static char licensing_public_key[] = "-----BEGIN PUBLIC KEY-----\n"
	"MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEA0zcK4H4q9NWC4MkW7y2G\n"
	"V/Tm91U5pnL+VkzwlrXSI/Eh45pGeNfosSVN2NGQciEjeDrcbPdP4QbWguHIDDmi\n"
	"CJ0vFAMyHchNIJa5nt0QAW3V7nQ217PYLr0A3KVkVqGwR5+Z1i/1xEIuXy4ZHUqd\n"
	"pJlYfkmJIcGgGGpUDoZhEB1zLySutIxArmuMqj6DNt9fYfsMCYTBjmVY2IJfgNha\n"
	"zrLrQY+SNYjad1A0XuegZy48fKM9hqXR55ZO1yVZ3a7Mea9xwSsXcuAu3ZRL0kWt\n"
	"p/yNWqAco26fJ00veqVA+rOT0qhW6VmRn9eE4pJoOhkUXYnw2xY5yo0oROAnuQ18\n"
	"kZUzkfcHIVWjLqfK0+rW4Bmbx0jjYKZRo5kQKwWBghc+ASf9m5LARtj4qx9ihicl\n"
	"gUdhdEQr4sVSYPoqSj5BTH/oaC04qw2bwx/TKFM2+YZ6O6fee85Su4pYTRznzGL0\n"
	"7B4xReWpLfylAKkex+lmkVfeJ+O5ZwB/Id77oZhrghpi9ylMn+slopBnOyJlvz2t\n"
	"2z6DVi1Ryn1p59t1b4VTyMTot3QaMGD3y8KRDvooDfY5jDtANirG0W9ugXlBOCyT\n"
	"3ML7CaMgTcI24R33lVF/jtNfOMScKj+J9/d0qY6LIYf4U55oda4RUk+a++PW3fCm\n"
	"eOUVXKmEsIkzo5YsAokiMeUCAwEAAQ==\n"
	"-----END PUBLIC KEY-----\n";

/**
 * Read file into an allocated buffer
 * @param path 	file path
 * @return 		string or NULL
 */
char *readFile(char *path) {
	char *source = NULL;
	FILE *fp = fopen(path, "rb");
	if (fp != NULL) {
		/* Go to the end of the file. */
		if (fseek(fp, 0L, SEEK_END) == 0) {
			/* Get the size of the file. */
			size_t bufsize = ftell(fp);
			if (bufsize == -1) {
				fprintf(stderr, "Error reading file %s\n", path);
				return NULL;
			}

			/* Allocate our buffer to that size. */
			source = malloc(sizeof(char) * (bufsize + 1));
			if (source == NULL) {
				fprintf(stderr, "Error reading file %s\n", path);
				return NULL;
			}

			/* Go back to the start of the file. */
			if (fseek(fp, 0L, SEEK_SET) != 0) {
				fprintf(stderr, "Error reading file %s\n", path);
				free(source);
				return NULL;
			}

			/* Read the entire file into memory. */
			size_t fileLen = fread(source, sizeof(char), bufsize, fp);
			if (ferror(fp) != 0) {
				fprintf(stderr, "Error reading file %s\n", path);
				free(source);
				return NULL;
			}
			else {
				source[fileLen++] = '\0'; /* Just to be safe. */
			}
		}
		fclose(fp);
	}
	return source;
}

/**
 Function for tokenizing strings (extends strtok function)
 * @param str 		string to tokenize (in)
 * @param delims	substring delimiters (in)
 * @param len 		length of the returned string array (out)
 * @return 			a ptr to an array of ptrs to strings
 * @note			consecutive delims will return empty string in array
 * @note			the return array is terminated with a null ptr '\0'
 */
char **strsplit(char *str, const char delims[], size_t *len) {
	char *save, *tok;        /* holds tok val btwn calls */
	char **result = NULL;    /* set result to NULL */
	char *tmp = strdup(str); /* leaves original str intact */
	size_t delims_size = strlen(delims);
	size_t count = 0;        /* number of main strings */
	size_t sub_count = 0;    /* number of substrings */
	int i = 0;

	/* get number of delims in str */
	do {
		tmp += delims_size;
		count++;
	} while ((tmp = strstr(tmp, delims)) != NULL);
	count++; /* add one for trailing token */
	tmp = strdup(str);

	save = malloc(sizeof(char) * strlen(str));
	result = malloc(sizeof(char *) * count);

	if (result && save) {
		while ((tok = strstr(tmp, delims)) != NULL) {
			strncpy(save, tmp, (tok - tmp));
			save[(tok - tmp)] = '\0';
//            printf("Token extracted: <<%s>>\n", save);
			result[i++] = strdup(save);
			tok += delims_size;
			tmp = tok;
		} /* grab trailing token */
		if (tmp && tmp[0] != '\0') {
			result[i++] = strdup(tmp);
//            printf("Token extracted: <<%s>>\n", tmp);
		} /* set last ptr to NULL */
		result[i] = '\0';
		*len = count; /* pass num toks */
	}
	else { /* set len to 0 on error */
		*len = 0;
	}
	if (save) free(save);
	return result;
}

/**
 * Decodes a base64 encoded string
 * @param b64message
 * @param out_length
 * @return
 */
unsigned char *b64decode(char *b64message, size_t *out_length) {
	BIO *b64_bio, *mem_bio;
	size_t b64_len = strlen(b64message);
	unsigned char *base64_decoded = calloc((b64_len * 3) / 4 + 1, sizeof(char));
	b64_bio = BIO_new(BIO_f_base64());
	mem_bio = BIO_new(BIO_s_mem());
	BIO_write(mem_bio, b64message, b64_len);
	BIO_push(b64_bio, mem_bio);
	if (b64message[b64_len-1] != '\n') {
		BIO_set_flags(b64_bio, BIO_FLAGS_BASE64_NO_NL);
	}
	int decoded_byte_index = 0;
	while (0 < BIO_read(b64_bio, base64_decoded + decoded_byte_index, 1)) {
		decoded_byte_index++;
	}
	*out_length = decoded_byte_index;
	BIO_free_all(b64_bio);
	return base64_decoded;
}

/**
 * Create an RSA key info struct
 * @param key
 * @param public
 * @return
 */
RSA *createRSA(unsigned char *key, int public) {
	RSA *rsa = NULL;
	BIO *keybio = NULL;

	keybio = BIO_new_mem_buf(key, -1);
	if (keybio == NULL) {
		fprintf(stderr, "Failed to create key BIO\n");
		return NULL;
	}
	if (public) {
		rsa = PEM_read_bio_RSA_PUBKEY(keybio, &rsa, NULL, NULL);
	}
	else {
		rsa = PEM_read_bio_RSAPrivateKey(keybio, &rsa, NULL, NULL);
	}
	if (rsa == NULL) {
		fprintf(stderr, "Failed to create RSA\n");
		free(keybio);
		return NULL;
	}

	if (keybio) { BIO_free(keybio); }
	return rsa;
}

/**
 * Verify a binary signature using RSA
 * @param msg
 * @param msglen
 * @param sig
 * @param siglen
 * @param pubkey
 * @return
 */
int verifyRSA(const unsigned char *msg, size_t msglen, unsigned char *sig, size_t siglen, unsigned char *pubkey) {
	unsigned char hash[SHA512_DIGEST_LENGTH];

	RSA *rsa = createRSA(pubkey, true);
	if (rsa == NULL) {
		goto verifyRSA_failure;
	}

	if (!SHA512(msg, msglen, hash)) {
		goto verifyRSA_failure;
	}

	if (!RSA_verify(NID_sha512, hash, sizeof(hash), sig, (unsigned int) siglen, rsa)) {
		goto verifyRSA_failure;
	}

	if (rsa) { RSA_free(rsa); }
	return true;
verifyRSA_failure:
	if (rsa) { RSA_free(rsa); }
	return false;
}

/**
 * Validate a dsiprouter license
 * current license format:
 * dsiprouter_unique_id,license_type,expiration_date
 * @param license_file 		path to dsip license
 * @param signature_file	path to license signature
 * @param uuid_file			path to dsip uuid
 * @return 					true or false
 */
int validate_license(char *license_file, char *signature_file, char *uuid_file) {
	char *license = NULL, *dsip_uuid = NULL, *signature_b64 = NULL;
	unsigned char* signature = NULL;
	char **fields = NULL;
	size_t sig_len, fields_len = 0;
	int status = false;

	// get data from files
	license = readFile(license_file);
	dsip_uuid = readFile(uuid_file);
	signature_b64 = readFile(signature_file);
	if (license == NULL || dsip_uuid == NULL || signature_b64 == NULL) {
		goto validate_license_ret;
	}

	// validate license hasn't been changed using signature
	signature = b64decode(signature_b64, &sig_len);
	if (signature == NULL) {
		goto validate_license_ret;
	}
	if (!verifyRSA(license, strlen(license), signature, sig_len, licensing_public_key)) {
		goto validate_license_ret;
	}

	// parse fields from license
	fields = strsplit(license, ",", &fields_len);
	if (fields == NULL) {
		goto validate_license_ret;
	}

	// validate this license is valid for this instance
	if (strcmp(fields[0], dsip_uuid) != 0) {
		goto validate_license_ret;
	}

	// validate license type
	if (strcmp(fields[1], "enterprise") != 0) {
		goto validate_license_ret;
	}

	// validate expiration date
	time_t now = time(NULL);
	time_t expires = (time_t) atoll(fields[2]);
	if (difftime(expires, now) <= 0) {
		goto validate_license_ret;
	}

	// passed all checks
	status = true;

validate_license_ret:
	if (license) { free(license); }
	if (signature_b64) { free(signature_b64); }
	if (signature) { free(signature); }
	if (dsip_uuid) { free(dsip_uuid); }
	if (fields) { free(fields); }
	return status;
}

/* paths in real application should be:
 * license_file:	/etc/dsiprouter/license.txt
 * signature_file:	/etc/dsiprouter/license-sig.b64
 * uuid_file: 		/etc/dsiprouter/uuid.txt */
int main() {
	if (validate_license("resources/license-good.txt", "resources/license-good-sig.b64", "resources/dsip-uuid.txt")) {
		printf("license-good.txt:	valid\n");
	}
	else {
		printf("license-good.txt:	invalid\n");
	}
	if (validate_license("resources/license-bad.txt", "resources/license-bad-sig.b64", "resources/dsip-uuid.txt")) {
		printf("license-bad.txt:	valid\n");
	}
	else {
		printf("license-bad.txt:	invalid\n");
	}
	return EXIT_SUCCESS;
}