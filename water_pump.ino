// Pin definitions
#define RELAY_PIN D1
#define RECEIVER_PIN D2
#define TRIG_PIN D5
#define ECHO_PIN D6

// Variables
long duration;
float distance;
int pwmValue;

void setup() {
  Serial.begin(9600);

  pinMode(RELAY_PIN, OUTPUT);
  pinMode(RECEIVER_PIN, INPUT);
  pinMode(TRIG_PIN, OUTPUT);
  pinMode(ECHO_PIN, INPUT);

  digitalWrite(RELAY_PIN, LOW); // Pump OFF
}

void loop() {

  // ===== 1. Read PWM from receiver =====
  pwmValue = pulseIn(RECEIVER_PIN, HIGH, 25000); // microseconds

  // ===== 2. Read distance from sensor =====
  digitalWrite(TRIG_PIN, LOW);
  delayMicroseconds(2);

  digitalWrite(TRIG_PIN, HIGH);
  delayMicroseconds(10);
  digitalWrite(TRIG_PIN, LOW);

  duration = pulseIn(ECHO_PIN, HIGH);
  distance = duration * 0.034 / 2; // cm

  // ===== 3. Logic =====

  // If switch ON (PWM > 1500)
  if (pwmValue > 1500) {

    // If far → full power (ON)
    if (distance > 30) {
      digitalWrite(RELAY_PIN, HIGH); // Pump ON
    }

    // If close → reduce (simulate by pulsing)
    else if (distance > 10 && distance <= 30) {
      digitalWrite(RELAY_PIN, HIGH);
      delay(200);   // ON
      digitalWrite(RELAY_PIN, LOW);
      delay(300);   // OFF (weaker flow)
    }

    // Very close → OFF
    else {
      digitalWrite(RELAY_PIN, LOW);
    }

  } else {
    // Switch OFF
    digitalWrite(RELAY_PIN, LOW);
  }

  // Debug
  Serial.print("PWM: ");
  Serial.print(pwmValue);
  Serial.print("  Distance: ");
  Serial.println(distance);

  delay(50);
}