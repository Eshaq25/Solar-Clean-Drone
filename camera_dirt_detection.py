import cv2
import numpy as np

# فتح الكاميرا
cap = cv2.VideoCapture(0)  # 0 تعني الكاميرا المدمجة

# التحقق من أن الكاميرا تعمل بشكل صحيح
if not cap.isOpened():
    print("Error: Unable to access the camera.")
    exit()

while True:
    # قراءة الإطارات من الكاميرا
    ret, frame = cap.read()

    if not ret:
        print("Error: Failed to capture image.")
        break

    # تحويل الإطار إلى تدرج الرمادي
    gray_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)

    # استخدام تحسين التباين باستخدام Histogram Equalization
    equalized_frame = cv2.equalizeHist(gray_frame)

    # تطبيق Gaussian Blur لتقليل الضوضاء
    blurred_frame = cv2.GaussianBlur(equalized_frame, (5, 5), 0)

    # تطبيق Canny Edge Detection لاكتشاف الحواف
    edges = cv2.Canny(blurred_frame, 100, 200)

    # تحسين الصورة باستخدام العمليات المورفولوجية (dilation)
    kernel = np.ones((5, 5), np.uint8)
    dilated_frame = cv2.dilate(edges, kernel, iterations=1)

    # حساب نسبة الأوساخ بناءً على التباين
    dirt_area = np.sum(dilated_frame == 255)  # حساب البكسلات المتسخة
    total_area = dilated_frame.size  # المساحة الكلية للإطار

    # حساب نسبة الأوساخ
    dirt_percentage = (dirt_area / total_area) * 100

    # إضافة التصنيف بناءً على النسبة المئوية
    if dirt_percentage < 20:
        status = "LOW DUST"
        color = (0, 255, 0)  # أخضر (دليل على مستوى منخفض للأوساخ)
    elif dirt_percentage < 50:
        status = "MEDIUM DUST"
        color = (0, 255, 255)  # أصفر (دليل على مستوى متوسط للأوساخ)
    else:
        status = "HIGH DUST"
        color = (0, 0, 255)  # أحمر (دليل على مستوى مرتفع للأوساخ)

    # عرض النتيجة على الفيديو مع النص
    cv2.putText(frame, f"Contrast: {dirt_percentage:.2f}%", (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 1, color, 2)
    cv2.putText(frame, f"Dust Score: {dirt_percentage:.2f}", (10, 70), cv2.FONT_HERSHEY_SIMPLEX, 1, color, 2)
    cv2.putText(frame, f"Decision: {status}", (10, 110), cv2.FONT_HERSHEY_SIMPLEX, 1, color, 2)

    # عرض الإطار
    cv2.imshow('Camera Feed', frame)

    # الخروج من الحلقة عند الضغط على زر 'q'
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

# إيقاف الكاميرا عند الخروج
cap.release()
cv2.destroyAllWindows()
