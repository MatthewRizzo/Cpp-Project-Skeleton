#include "example_lib/lib.hpp"
#include <UnitTest++/UnitTest++.h>

SUITE(Foo)
{
    TEST(Placeholder)
    {
        example_namespace::example_function();
        CHECK(true);
    }
};

int main()
{
    return UnitTest::RunAllTests();
}
