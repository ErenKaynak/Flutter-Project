const functions = require("firebase-functions");
const nodemailer = require("nodemailer");

// Configure nodemailer with Gmail
const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: process.env.EMAIL_USER || "beykozengineeringproject@gmail.com",
    pass: process.env.EMAIL_PASSWORD, // Use environment variable for app password
  },
  tls: {
    rejectUnauthorized: false // Only use this in development
  }
});

// Verify transporter configuration
transporter.verify(function(error, success) {
  if (error) {
    console.error('SMTP configuration error:', error);
  } else {
    console.log('SMTP server is ready to send messages');
  }
});

exports.sendOrderReceipt = functions.https.onCall(async (data, _context) => {
  try {
    const {
      customerEmail,
      customerName,
      orderNumber,
      items,
      totalAmount,
      orderDate,
      shippingAddress,
    } = data;

    // Generate HTML email template
    const htmlContent = generateReceiptTemplate({
      customerName,
      orderNumber,
      items,
      totalAmount,
      orderDate: new Date(orderDate),
      shippingAddress,
    });

    // Send email
    const mailOptions = {
      from: "Engineering Project <beykozengineeringproject@gmail.com>",
      to: customerEmail,
      subject: `Sipariş Onayı - ${orderNumber}`,
      html: htmlContent,
    };

    await transporter.sendMail(mailOptions);
    return { success: true, message: "Email sent successfully" };
  } catch (error) {
    console.error("Error sending email:", error);
    throw new functions.https.HttpsError("internal", "Failed to send email");
  }
});

// Generate HTML receipt template
function generateReceiptTemplate({
  customerName,
  orderNumber,
  items,
  totalAmount,
  orderDate,
  shippingAddress,
}) {
  const formatCurrency = (amount) => {
    return new Intl.NumberFormat("tr-TR", {
      style: "currency",
      currency: "TRY",
    }).format(amount);
  };

  const formatDate = (date) => {
    return new Intl.DateTimeFormat("tr-TR", {
      year: "numeric",
      month: "long",
      day: "numeric",
    }).format(date);
  };

  return `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <style>
        body {
          font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
          line-height: 1.6;
          color: #333;
          margin: 0;
          padding: 0;
        }
        .container {
          max-width: 600px;
          margin: 0 auto;
          padding: 20px;
        }
        .header {
          background: linear-gradient(135deg, #ff4b4b 0%, #ff7676 100%);
          color: white;
          padding: 30px;
          text-align: center;
          border-radius: 10px 10px 0 0;
        }
        .content {
          background: #ffffff;
          padding: 30px;
          border: 1px solid #e0e0e0;
          border-radius: 0 0 10px 10px;
        }
        .order-info {
          margin-bottom: 30px;
        }
        .items-table {
          width: 100%;
          border-collapse: collapse;
          margin: 20px 0;
        }
        .items-table th, .items-table td {
          padding: 12px;
          text-align: left;
          border-bottom: 1px solid #e0e0e0;
        }
        .items-table th {
          background-color: #f8f9fa;
          font-weight: 600;
        }
        .total {
          text-align: right;
          font-size: 1.2em;
          font-weight: bold;
          margin-top: 20px;
        }
        .footer {
          text-align: center;
          margin-top: 30px;
          color: #666;
          font-size: 0.9em;
        }
        .button {
          display: inline-block;
          padding: 12px 24px;
          background: linear-gradient(135deg, #ff4b4b 0%, #ff7676 100%);
          color: white;
          text-decoration: none;
          border-radius: 5px;
          margin-top: 20px;
        }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>Siparişiniz İçin Teşekkürler!</h1>
          <p>Sipariş Onayı</p>
        </div>
        <div class="content">
          <div class="order-info">
            <h2>Sipariş Detayları</h2>
            <p><strong>Sipariş Numarası:</strong> ${orderNumber}</p>
            <p><strong>Tarih:</strong> ${formatDate(orderDate)}</p>
            <p><strong>Müşteri:</strong> ${customerName}</p>
            <p><strong>Teslimat Adresi:</strong> ${shippingAddress}</p>
          </div>
          
          <table class="items-table">
            <thead>
              <tr>
                <th>Ürün</th>
                <th>Adet</th>
                <th>Fiyat</th>
                <th>Toplam</th>
              </tr>
            </thead>
            <tbody>
              ${items.map(item => `
                <tr>
                  <td>${item.name}</td>
                  <td>${item.quantity}</td>
                  <td>${formatCurrency(item.price)}</td>
                  <td>${formatCurrency(item.price * item.quantity)}</td>
                </tr>
              `).join("")}
            </tbody>
          </table>
          
          <div class="total">
            <p>Toplam Tutar: ${formatCurrency(totalAmount)}</p>
          </div>
          
          <div style="text-align: center;">
            <a href="#" class="button">Sipariş Durumunu Görüntüle</a>
          </div>
        </div>
        
        <div class="footer">
          <p>Sorularınız için destek ekibimizle iletişime geçebilirsiniz.</p>
          <p>© 2024 Engineering Project. Tüm hakları saklıdır.</p>
        </div>
      </div>
    </body>
    </html>
  `;
} 