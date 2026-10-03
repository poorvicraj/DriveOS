#pragma once

#include <iostream>
#include <vector>
#include <string>
#include <cmath>
#include <functional>

namespace testing {

class Test {
public:
    virtual ~Test() = default;
    virtual void TestBody() = 0;
};

struct TestInfo {
    std::string suite;
    std::string name;
    std::function<void()> run;
};

inline std::vector<TestInfo>& GetTests() {
    static std::vector<TestInfo> tests;
    return tests;
}

inline bool RegisterTest(const std::string& suite, const std::string& name, std::function<void()> run) {
    GetTests().push_back({suite, name, std::move(run)});
    return true;
}

inline void InitGoogleTest(int*, char**) {}

inline int g_failures = 0;

} // namespace testing

inline int RUN_ALL_TESTS() {
    int passed = 0;
    auto& tests = testing::GetTests();
    std::cout << "[==========] Running " << tests.size() << " test cases." << std::endl;
    for (const auto& t : tests) {
        std::cout << "[ RUN      ] " << t.suite << "." << t.name << std::endl;
        int oldFailures = testing::g_failures;
        try {
            t.run();
        } catch (const std::exception& e) {
            std::cout << "  Exception caught: " << e.what() << std::endl;
            testing::g_failures++;
        }
        if (testing::g_failures == oldFailures) {
            std::cout << "[       OK ] " << t.suite << "." << t.name << std::endl;
            passed++;
        } else {
            std::cout << "[  FAILED  ] " << t.suite << "." << t.name << std::endl;
        }
    }
    std::cout << "[==========] " << tests.size() << " tests ran. "
              << passed << " passed, " << testing::g_failures << " failed." << std::endl;
    return testing::g_failures == 0 ? 0 : 1;
}

#define TEST(suite, name) \
    class suite##_##name##_Test : public testing::Test { \
    public: \
        void TestBody() override; \
    }; \
    static bool suite##_##name##_registered = testing::RegisterTest(#suite, #name, []() { \
        suite##_##name##_Test t; \
        t.TestBody(); \
    }); \
    void suite##_##name##_Test::TestBody()

#define EXPECT_TRUE(c) do { if (!(c)) { std::cout << "  Failure: " #c " is false at " << __FILE__ << ":" << __LINE__ << "\n"; testing::g_failures++; } } while(0)
#define EXPECT_FALSE(c) do { if ((c)) { std::cout << "  Failure: " #c " is true at " << __FILE__ << ":" << __LINE__ << "\n"; testing::g_failures++; } } while(0)
#define EXPECT_EQ(a, b) do { if (!((a) == (b))) { std::cout << "  Failure: " #a " != " #b " at " << __FILE__ << ":" << __LINE__ << "\n"; testing::g_failures++; } } while(0)
#define EXPECT_FLOAT_EQ(a, b) do { if (std::fabs((a) - (b)) > 0.001f) { std::cout << "  Failure: " #a " != " #b " at " << __FILE__ << ":" << __LINE__ << "\n"; testing::g_failures++; } } while(0)
#define EXPECT_GT(a, b) do { if (!((a) > (b))) { std::cout << "  Failure: " #a " <= " #b " at " << __FILE__ << ":" << __LINE__ << "\n"; testing::g_failures++; } } while(0)
#define EXPECT_LT(a, b) do { if (!((a) < (b))) { std::cout << "  Failure: " #a " >= " #b " at " << __FILE__ << ":" << __LINE__ << "\n"; testing::g_failures++; } } while(0)
#define EXPECT_LE(a, b) do { if (!((a) <= (b))) { std::cout << "  Failure: " #a " > " #b " at " << __FILE__ << ":" << __LINE__ << "\n"; testing::g_failures++; } } while(0)
#define EXPECT_GE(a, b) do { if (!((a) >= (b))) { std::cout << "  Failure: " #a " < " #b " at " << __FILE__ << ":" << __LINE__ << "\n"; testing::g_failures++; } } while(0)
#define EXPECT_NEAR(a, b, eps) do { if (std::fabs((a) - (b)) > (eps)) { std::cout << "  Failure: " #a " not near " #b " at " << __FILE__ << ":" << __LINE__ << "\n"; testing::g_failures++; } } while(0)
#define EXPECT_NO_THROW(stmt) do { try { stmt; } catch (...) { std::cout << "  Failure: exception thrown at " << __FILE__ << ":" << __LINE__ << "\n"; testing::g_failures++; } } while(0)

#define ASSERT_TRUE(c) EXPECT_TRUE(c)
#define ASSERT_FALSE(c) EXPECT_FALSE(c)
#define ASSERT_EQ(a, b) EXPECT_EQ(a, b)
#define ASSERT_NE(a, b) do { if ((a) == (b)) { std::cout << "  Failure: " #a " == " #b " at " << __FILE__ << ":" << __LINE__ << "\n"; testing::g_failures++; } } while(0)

