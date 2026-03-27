---
name: flutter-clean-solid-dry
description: Principles of software design (DRY, SOLID, Clean Code) applied to Flutter/Dart development with practical examples, anti-patterns, and integration with existing skills (flutter-dart-code-review, flutter-expert).
origin: ECC
---

# Flutter Clean Code, SOLID, and DRY Principles

Guidelines for writing maintainable, reusable, and scalable Flutter/Dart code by applying fundamental software design principles. This skill complements `flutter-dart-code-review` (checklist) and `flutter-expert` (implementation) by providing the theoretical foundation and concrete patterns.

---

## 1. DRY (Don't Repeat Yourself)

### Principles
- Every piece of knowledge must have a single, unambiguous, authoritative representation within a system.
- Avoid duplication of code, logic, or data.

### Flutter/Dart Applications

#### 1.1 Extract Reusable Widgets
**Problem:** Similar UI snippets repeated across multiple build methods.
**Solution:** Extract into a separate widget class.

```dart
// BAD: Duplicated styled container
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(blurRadius: 4, color: Colors.black12)],
      ),
      child: Text('Home'),
    );
  }
}

// In another file...
class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(blurRadius: 4, color: Colors.black12)],
      ),
      child: Text('Profile'),
    );
  }
}

// GOOD: Reusable Card widget
class StyledCard extends StatelessWidget {
  final Widget child;
  const StyledCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(blurRadius: 4, color: Colors.black12)],
      ),
      child: child,
    );
  }
}
```

#### 1.2 Centralize Constants and Configurations
**Problem:** Magic numbers/strings scattered throughout code.
**Solution:** Define constants in a dedicated file or class.

```dart
// BAD
class ProductCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120, // magic number
      margin: EdgeInsets.all(8), // magic number
      // ...
    );
  }
}

// GOOD
class AppDimensions {
  static const double productCardHeight = 120.0;
  static const double smallPadding = 8.0;
  static const double mediumPadding = 16.0;
}
```

#### 1.3 Reusable Business Logic
**Problem:** Same validation or transformation logic in multiple places.
**Solution:** Extract to utility classes or extension methods.

```dart
// BAD: Duplicated email validation
bool isValidEmail(String email) {
  return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
}

// In another file...
bool validateEmail(String email) {
  return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
}

// GOOD: Extension method
extension EmailValidation on String {
  bool get isValidEmail {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(this);
  }
}
```

#### 1.4 Generic Components
**Problem:** Near-identical components with minor variations.
**Solution:** Parameterize differences, create generic widgets.

```dart
// BAD: Two almost identical list widgets
class UserList extends StatelessWidget {
  final List<User> users;
  // ...
}

class ProductList extends StatelessWidget {
  final List<Product> products;
  // ...
}

// GOOD: Generic ListView.builder
class GenericListView<T> extends StatelessWidget {
  final List<T> items;
  final Widget Function(BuildContext, T) itemBuilder;
  const GenericListView({required this.items, required this.itemBuilder});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) => itemBuilder(context, items[index]),
    );
  }
}
```

### When NOT to Apply DRY
- **Premature abstraction:** Don't extract a widget until you see at least three instances of duplication.
- **Accidental similarity:** Two pieces of code that look similar but have different semantic meaning.
- **Over-engineering:** Creating abstractions that make code harder to understand.

---

## 2. SOLID Principles

### 2.1 Single Responsibility Principle (SRP)
*A class should have only one reason to change.*

#### Flutter/Dart Applications

**Problem:** Widgets handling too many responsibilities (UI, state, business logic).
**Solution:** Separate concerns into different classes.

```dart
// BAD: Widget doing too much
class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  Future<void> login() async {
    setState(() => isLoading = true);
    // API call directly in widget
    final response = await http.post(
      Uri.parse('https://api.example.com/login'),
      body: {'email': emailController.text, 'password': passwordController.text},
    );
    // Parse response
    // Save token to shared preferences
    // Navigate
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    // UI code...
  }
}

// GOOD: Separated responsibilities
class LoginViewModel extends ChangeNotifier {
  final AuthService authService;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  LoginViewModel({required this.authService});

  Future<void> login() async {
    isLoading = true;
    notifyListeners();
    try {
      await authService.login(emailController.text, passwordController.text);
      // Success handling
    } catch (e) {
      // Error handling
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}

class LoginScreen extends StatelessWidget {
  final LoginViewModel viewModel;
  // UI only, delegates logic to viewModel
}
```

### 2.2 Open/Closed Principle (OCP)
*Software entities should be open for extension, but closed for modification.*

#### Flutter/Dart Applications

**Problem:** Adding new functionality requires modifying existing code.
**Solution:** Use inheritance, composition, or strategy pattern.

```dart
// BAD: Adding new payment method requires modifying existing class
class PaymentProcessor {
  void processPayment(String type, double amount) {
    if (type == 'credit_card') {
      // process credit card
    } else if (type == 'paypal') {
      // process PayPal
    } else if (type == 'bank_transfer') {
      // add new if-else when adding new method
    }
  }
}

// GOOD: Open for extension via interface
abstract class PaymentMethod {
  Future<void> processPayment(double amount);
}

class CreditCardPayment implements PaymentMethod {
  @override
  Future<void> processPayment(double amount) async { /* ... */ }
}

class PayPalPayment implements PaymentMethod {
  @override
  Future<void> processPayment(double amount) async { /* ... */ }
}

class PaymentProcessor {
  final PaymentMethod paymentMethod;
  PaymentProcessor({required this.paymentMethod});

  Future<void> process(double amount) async {
    await paymentMethod.processPayment(amount);
  }
}

// Adding new method doesn't require modifying existing code
class CryptoPayment implements PaymentMethod {
  @override
  Future<void> processPayment(double amount) async { /* ... */ }
}
```

### 2.3 Liskov Substitution Principle (LSP)
*Objects 
