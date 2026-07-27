// crime.cpp — READ-ONLY EXHIBIT. Do not compile; you are here to read.
// The bug class: CWE-416, use-after-free via vector reallocation.
#include <cstdio>
#include <vector>

int main() {
    std::vector<int> ports = {22, 80, 443};
    const int& first = ports[0];      // a reference into the buffer
    for (int p = 8000; p < 8032; ++p) {
        ports.push_back(p);           // growth may reallocate the buffer
    }
    std::printf("first = %d\n", first); // reads freed memory
    return 0;
}
