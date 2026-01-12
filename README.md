# Fluxion Token & Factory

Implementing an upgradeable ERC20 token with Permit and meta-transaction support, along with a factory for deploying clones.

## Contract Description

### Fluxion (v1)
*   **Standard**: ERC20
*   **Upgradeability**: UUPS (Universal Upgradeable Proxy Standard)
*   **Extensions**:
    *   `ERC20Permit`: Support for signatures for transaction approvals (gasless approvals).
    *   `AccessControlEnumerable`: Role management (`DEFAULT_ADMIN_ROLE`, `MINTER_ROLE`, `UPGRADER_ROLE`).

### Fluxion (v2)
*   Inherits v1 functionality.
*   **Meta-transactions**: Added support for a Trusted Forwarder to implement gasless transactions (similar to ERC2771).

### Factory
*   Uses `Clones` library (EIP-1167) for cheap deployment of minimal proxy contracts.
*   Allows creating clones of the `Fluxion` implementation.
*   Supports deterministic deployment (`create2`).

## Installation and Usage

### Prerequisites
*   [Foundry](https://book.getfoundry.sh/getting-started/installation)
*   Git

### Installation
```bash
git clone <repo_url>
cd my-foundry-project
forge install
```

### Build
```bash
forge build
```

### Testing
Run all tests:
```bash
forge test
```

Run a specific test with verbose output:
```bash
forge test --match-contract FluxionPermitTest -vvvv
```

## Deployment

Scripts in the `script/` folder are used for deployment.
You need to create a `.env` file and add the necessary variables (PRIVATE_KEY, RPC_URL, ETHERSCAN_API_KEY).

### Deploy Factory and Implementation
```bash
forge script script/DeployFactory.s.sol --rpc-url $RPC_URL --broadcast --verify
```

### Upgrade to v2
```bash
forge script script/UpgradeFluxion.s.sol --rpc-url $RPC_URL --broadcast --verify
```

### Other Scripts
*   `script/InteractWithFluxion.s.sol`: Script for interacting with the deployed token (minting, transfers).
*   `script/SmokeTestFactory.s.sol`: Smoke tests to verify the factory and clones in a testnet.

## Verification
Scripts are configured for automatic contract verification on Etherscan (if `ETHERSCAN_API_KEY` is provided).

## Project Structure
*   `src/`: Contract source code.
*   `script/`: Deployment and interaction scripts.
*   `test/`: Tests (Foundry).
*   `plans/`: Plans and task documentation.

---

# Fluxion Token & Factory (RU)

Проект, включающий реализацию обновляемого ERC20 токена с поддержкой Permit и мета-транзакций, а также фабрику для развертывания клонов.

## Описание контрактов

### Fluxion (v1)
*   **Стандарт**: ERC20
*   **Обновляемость**: UUPS (Universal Upgradeable Proxy Standard)
*   **Расширения**:
    *   `ERC20Permit`: Поддержка подписей для одобрения транзакций (gasless approvals).
    *   `AccessControlEnumerable`: Управление ролями (`DEFAULT_ADMIN_ROLE`, `MINTER_ROLE`, `UPGRADER_ROLE`).

### Fluxion (v2)
*   Наследует функционал v1.
*   **Мета-транзакции**: Добавлена поддержка доверенного форвардера (Trusted Forwarder) для реализации gasless-транзакций (аналог ERC2771).

### Factory
*   Использует библиотеку `Clones` (EIP-1167) для дешевого развертывания минимальных прокси-контрактов.
*   Позволяет создавать клоны реализации `Fluxion`.
*   Поддерживает детерминированное развертывание (`create2`).

## Установка и запуск

### Предварительные требования
*   [Foundry](https://book.getfoundry.sh/getting-started/installation)
*   Git

### Установка
```bash
git clone <repo_url>
cd my-foundry-project
forge install
```

### Сборка
```bash
forge build
```

### Тестирование
Запуск всех тестов:
```bash
forge test
```

Запуск конкретного теста с подробным выводом:
```bash
forge test --match-contract FluxionPermitTest -vvvv
```

## Развертывание (Deployment)

Для развертывания используются скрипты в папке `script/`.
Необходимо создать файл `.env` и добавить туда необходимые переменные (PRIVATE_KEY, RPC_URL, ETHERSCAN_API_KEY).

### Развертывание Фабрики и Реализации
```bash
forge script script/DeployFactory.s.sol --rpc-url $RPC_URL --broadcast --verify
```

### Обновление до v2
```bash
forge script script/UpgradeFluxion.s.sol --rpc-url $RPC_URL --broadcast --verify
```

### Другие скрипты
*   `script/InteractWithFluxion.s.sol`: Скрипт для взаимодействия с развернутым токеном (минтинг, переводы).
*   `script/SmokeTestFactory.s.sol`: Smoke-тесты для проверки работоспособности фабрики и клонов в тестовой сети.

## Верификация
Скрипты настроены на автоматическую верификацию контрактов на Etherscan (при наличии `ETHERSCAN_API_KEY`).

## Структура проекта
*   `src/`: Исходный код контрактов.
*   `script/`: Скрипты для развертывания и взаимодействия.
*   `test/`: Тесты (Foundry).
*   `plans/`: Планы и документация по задаче.
