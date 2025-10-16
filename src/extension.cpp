#include "extension.hpp"

/**
 * @file extension.cpp
 * @brief Implement extension code here.
 */

ExampleExt g_ExampleExt;		/**< Global singleton for extension's main interface */

SMEXT_LINK(&g_ExampleExt);

cell_t Native_AddNums(IPluginContext *pContext, const cell_t *params) {
    return params[1] + params[2];
}

const sp_nativeinfo_t ExampleExtNatives[] = {
    {"AddNums", Native_AddNums},
    {NULL, NULL},
};

void ExampleExt::SDK_OnAllLoaded() {
    sharesys->AddNatives(myself, ExampleExtNatives);
}
