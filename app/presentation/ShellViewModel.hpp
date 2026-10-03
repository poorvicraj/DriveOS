#pragma once

#include "HomeViewModel.hpp"

namespace driveos::presentation {

/**
 * @brief ShellViewModel is an alias / wrapper over HomeViewModel to provide 100%
 * backwards compatibility for existing QML context references while establishing
 * the canonical HomeViewModel.
 */
class ShellViewModel : public HomeViewModel {
    Q_OBJECT
public:
    using HomeViewModel::HomeViewModel;
    ~ShellViewModel() override = default;
};

} // namespace driveos::presentation
