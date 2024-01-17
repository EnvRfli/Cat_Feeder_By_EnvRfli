const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.checkFoodStatusAndSendNotification = functions.database.ref('/path_to_food_status')
    .onUpdate((snapshot, context) => {
        const foodStatus = snapshot.after.val();

        if (foodStatus > 14) {
            const payload = {
                notification: {
                    title: 'Peringatan Tangki Makanan',
                    body: 'Tangki makanan habis!'
                }
            };

            // Kirim notifikasi ke semua device
            return admin.messaging().sendToTopic('foodStatusAlert', payload)
                .then(response => {
                    console.log('Notifikasi berhasil dikirim:', response);
                })
                .catch(error => {
                    console.log('Error mengirim notifikasi:', error);
                });
        }
    });
