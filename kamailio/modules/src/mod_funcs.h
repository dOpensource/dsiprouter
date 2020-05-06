#ifndef DSIPROUTER_LICENSING_MOD_FUNCS_H
#define DSIPROUTER_LICENSING_MOD_FUNCS_H

#include <stddef.h>
#include <openssl/pem.h>

char *readFile(char *path);
char **strsplit(char *str, const char delims[], size_t *len);
unsigned char *b64decode(char *b64message, size_t *out_length);
RSA *createRSA(unsigned char *key, int public);
int verifyRSA(const unsigned char *msg, size_t msglen, unsigned char *sig, size_t siglen, unsigned char *pubkey);
int validate_license(char *license_file, char *signature_file, char *uuid_file);

#endif //DSIPROUTER_LICENSING_MOD_FUNCS_H
