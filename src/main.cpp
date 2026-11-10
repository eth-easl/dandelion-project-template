// Example Dandelion function: upper-cases every item of every input set and
// writes the results to output set 0, keeping each item's ident and key.
//
// Replace the body of main() with your function's logic. A non-zero return
// value marks the invocation as failed.

#include "dandelion/runtime.h"

#include <cctype>
#include <cstdlib>
#include <cstring>
#include <iostream>

int main() {
    if (dandelion_output_set_count() < 1) {
        std::cerr << "Expected at least one output set." << std::endl;
        return 1;
    }

    for (size_t set_idx = 0; set_idx < dandelion_input_set_count(); set_idx++) {
        for (size_t itm_idx = 0; itm_idx < dandelion_input_buffer_count(set_idx); itm_idx++) {
            IoBuffer* in = dandelion_get_input(set_idx, itm_idx);

            // The runtime reads output buffers only after the function exits, so
            // they must stay alive until then: allocate them on the heap and never
            // free them (the sandbox reclaims all memory on teardown).
            char* data = static_cast<char*>(malloc(in->data_len));
            const char* in_data = static_cast<const char*>(in->data);
            for (size_t i = 0; i < in->data_len; i++) {
                data[i] = static_cast<char>(std::toupper(static_cast<unsigned char>(in_data[i])));
            }
            char* ident = static_cast<char*>(malloc(in->ident_len));
            memcpy(ident, in->ident, in->ident_len);

            IoBuffer out;
            out.ident = ident;
            out.ident_len = in->ident_len;
            out.data = data;
            out.data_len = in->data_len;
            out.key = in->key;
            dandelion_add_output(0, out);
        }
    }
    return 0;
}
