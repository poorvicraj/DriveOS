#include <gtest/gtest.h>
#include <QGuiApplication>

int main(int argc, char** argv) {
    ::testing::InitGoogleTest(&argc, argv);
    qputenv("QT_QPA_PLATFORM", "offscreen");
    QGuiApplication app(argc, argv);
    return RUN_ALL_TESTS();
}
