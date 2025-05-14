//==============================================================
// Copyright  2019 Intel Corporation
//
// SPDX-License-Identifier: MIT
// =============================================================


// This lab demonstrates the performance impacts of a basic optimization
// utilizing local (GPU) memory access for operations that can be accumulated
// before copying back to the host. HOWEVER, it can also demonstrate a
// performance pessimization depending on the system topology. Try running this
// lab on both a system with discrete CPU and GPU memory and a system with a
// unified memory architecture.


#include <malloc.h>
#include <iostream>
#include <chrono>
#include <array>

#include <sycl/sycl.hpp>

constexpr int MAXTHREADS=16;
constexpr int NUM=16384;
constexpr int MATRIXTILESIZE=16;
constexpr int WPT=8;

using namespace sycl;
using namespace std;

using namespace std;
template <typename T>
class MatrixBasic;

template <typename T>
class MatrixLocalAccess;

typedef unsigned long long UINT64;
typedef float TYPE;
typedef TYPE Array[NUM];


// Basic matrix multiply
void multiply_basic(int msize, int tidx, int numt, TYPE a[][NUM], TYPE b[][NUM], TYPE c[][NUM], TYPE t[][NUM]) {
    int i, j, k;

    // Declare a deviceQueue
    default_selector device;
    queue q(device);
    // Declare a 2 dimensional range
    range<2> matrix_range{NUM, NUM};

    // Declare 3 buffers and Initialize them
    buffer bufferA((TYPE*)a, range(matrix_range));
    buffer bufferB((TYPE*)b, range(matrix_range));
    buffer bufferC((TYPE*)c, range(matrix_range));

    // Submit our job to the queue
    q.submit([&](sycl::handler& h) {
        // Declare 3 accessors to our buffers. The first 2 read and the last
        // read_write
        accessor accessorA(bufferA, h, read_only);
        accessor accessorB(bufferB, h, read_only);
        accessor accessorC(bufferC, h);

        // Execute matrix multiply in parallel over our matrix_range
        // ind is an index into this range
        h.parallel_for<class MatrixBasic<TYPE> >(matrix_range,[=](sycl::id<2> ind) {
            int k;
            for (k = 0; k < NUM; k++) {
                // Perform computation ind[0] is row, ind[1] is col
                accessorC[ind[0]][ind[1]] += accessorA[ind[0]][k] * accessorB[k][ind[1]];
            }
        });
    }).wait();
}

// Replaces accessorC reference with a local variable
void multiply_local_access(int msize, int tidx, int numt, TYPE a[][NUM], TYPE b[][NUM],TYPE c[][NUM], TYPE t[][NUM]) {
    int i, j, k;

    // Declare a deviceQueue
    default_selector device;
    queue q(device);

    // Declare a 2 dimensional range
    range<2> matrix_range{NUM, NUM};

    // Declare 3 buffers and Initialize them
    buffer bufferA((TYPE*)a, range(matrix_range));
    buffer bufferB((TYPE*)b, range(matrix_range));
    buffer bufferC((TYPE*)c, range(matrix_range));

    // Submit our job to the queue
    q.submit([&](sycl::handler& h) {
        // Declare 3 accessors to our buffers. The first 2 read and the last
        // read_write
        accessor accessorA(bufferA, h, read_only);
        accessor accessorB(bufferB, h, read_only);
        accessor accessorC(bufferC, h);

        // Execute matrix multiply in parallel over our matrix_range
        // ind is an index into this range
        h.parallel_for<class MatrixLocalAccess<TYPE>>(matrix_range,[=](sycl::id<2> ind) {
            int k;
            TYPE acc = 0.0;
            for (k = 0; k < NUM; k++) {
                // Perform computation ind[0] is row, ind[1] is col
                acc += accessorA[ind[0]][k] * accessorB[k][ind[1]];
            }
            accessorC[ind[0]][ind[1]] = acc;
        });
    }).wait();
}


// routine to initialize an array with data
void InitArr(TYPE row, TYPE col, TYPE off, TYPE a[][NUM]) {
    int i, j;

    for (i = 0; i < NUM; i++) {
        for (j = 0; j < NUM; j++) {
            a[i][j] = row * i + col * j + off;
        }
    }
}

// routine to print out contents of small arrays
void PrintArr(char *name, TYPE Array[][NUM]) {
    int i, j;

    cout << "\n"<<name<<"\n";

    for (i = 0; i < NUM; i++) {
        for (j = 0; j < NUM; j++) {
            cout << Array[i][j] << "\t";
        }
        cout << std::endl;
    }
}

class TimeInterval {
public:
    TimeInterval() : start_(std::chrono::steady_clock::now()) {}

    double Elapsed() {
        auto now = std::chrono::steady_clock::now();
        return std::chrono::duration_cast<Duration>(now - start_).count();
    }

private:
    using Duration = std::chrono::duration<double>;
    std::chrono::steady_clock::time_point start_;
};


void multiply(void (*multfunc)(int, int, int, TYPE[][NUM], TYPE[][NUM], TYPE[][NUM], TYPE[][NUM]), char *name) {
    char *buf1, *buf2, *buf3, *buf4;
    char *addr1, *addr2, *addr3, *addr4;
    Array *a, *b, *c, *t;
    int Offset_Addr1 = 128, Offset_Addr2 = 192, Offset_Addr3 = 0, Offset_Addr4 = 64;

    buf1 = (char *)malloc(NUM * NUM * (sizeof(double)) + 1024);
    cout << "Address of buf1 = " << (void*)buf1 << std::endl;
    addr1 = buf1 + 256 - ((UINT64)buf1 % 256) + (UINT64)Offset_Addr1;
    cout << "Offset of buf1 = " << (void*)addr1 << std::endl;

    buf2 = (char *)malloc(NUM * NUM * (sizeof(double)) + 1024);
    cout << "Address of buf2 = " << (void*)buf2 << std::endl;
    addr2 = buf2 + 256 - ((UINT64)buf2 % 256) + (UINT64)Offset_Addr2;
    cout << "Offset of buf2 = " << (void*)addr2 << std::endl;

    buf3 = (char *)malloc(NUM * NUM * (sizeof(double)) + 1024);
    cout << "Address of buf3 = " << (void*)buf3 << std::endl;
    addr3 = buf3 + 256 - ((UINT64)buf3 % 256) + (UINT64)Offset_Addr3;
    cout << "Offset of buf3 = " << (void*)addr3 << std::endl;

    buf4 = (char *)malloc(NUM * NUM * (sizeof(double)) + 1024);
    cout << "Address of buf4 = " << (void*)buf4 << std::endl;
    addr4 = buf4 + 256 - ((UINT64)buf4 % 256) + (UINT64)Offset_Addr4;
    cout << "Offset of buf4 = " << (void*)addr4 << std::endl;

    a = (Array *)addr1;
    b = (Array *)addr2;
    c = (Array *)addr3;
    t = (Array *)addr4;

    InitArr(3, -2, 1, a);
    InitArr(-2, 1, 3, b);

    TimeInterval matrix_time;
    multfunc(NUM, MAXTHREADS, 0, a, b, c, t);
    double matrix_elapsed = matrix_time.Elapsed();
    cout << name << " elapsed time: " << matrix_elapsed << "s\n";

    free(buf1);
    free(buf2);
    free(buf3);
    free(buf4);
}

int main() {
    multiply(multiply_basic, "multiply_basic");
    multiply(multiply_local_access, "multiply_local_access");
}
