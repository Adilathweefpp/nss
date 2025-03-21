class Validators {
  // Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    
    // Regular expression for email validation
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }
  
  // Password validation
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    
    if (value.length < 6) {
      return 'Password must be at least 6 characters long';
    }
    
    return null;
  }
  
  // Name validation
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your name';
    }
    
    if (value.length < 3) {
      return 'Name must be at least 3 characters long';
    }
    
    return null;
  }
  
  // Volunteer ID validation
  static String? validateVolunteerId(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your volunteer ID';
    }
    
    return null;
  }
  
  // Blood group validation
  static String? validateBloodGroup(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please select your blood group';
    }
    
    // Valid blood groups: A+, A-, B+, B-, AB+, AB-, O+, O-
    final validBloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
    if (!validBloodGroups.contains(value)) {
      return 'Please select a valid blood group';
    }
    
    return null;
  }
  
  // Department validation
  static String? validateDepartment(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please select your department';
    }
    
    return null;
  }
  
  // Place validation
  static String? validatePlace(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your place';
    }
    
    return null;
  }
  
  // Event title validation
  static String? validateEventTitle(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter event title';
    }
    
    return null;
  }
  
  // Event description validation
  static String? validateEventDescription(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter event description';
    }
    
    return null;
  }
  
  // Event location validation
  static String? validateEventLocation(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter event location';
    }
    
    return null;
  }
  
  // Event participants validation
  static String? validateMaxParticipants(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter maximum participants';
    }
    
    final number = int.tryParse(value);
    if (number == null) {
      return 'Please enter a valid number';
    }
    
    if (number <= 0) {
      return 'Maximum participants must be greater than 0';
    }
    
    return null;
  }
  
  // Phone number validation
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your phone number';
    }
    
    // Regular expression for phone number validation (10 digits)
    final phoneRegex = RegExp(r'^\d{10}$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Please enter a valid 10-digit phone number';
    }
    
    return null;
  }
  
  // Required field validation
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'Please enter $fieldName';
    }
    
    return null;
  }
  
  // Numeric field validation
  static String? validateNumeric(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'Please enter $fieldName';
    }
    
    final number = double.tryParse(value);
    if (number == null) {
      return 'Please enter a valid number for $fieldName';
    }
    
    return null;
  }
  
  // Confirmation field validation
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    
    if (value != password) {
      return 'Passwords do not match';
    }
    
    return null;
  }
}