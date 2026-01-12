# Fluxion Token & Factory

Проект домашнего задания, включающий реализацию обновляемого ERC20 токена с поддержкой Permit и мета-транзакций, а также фабрику для развертывания клонов.

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
