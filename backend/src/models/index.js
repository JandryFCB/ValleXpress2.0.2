// Carga todos los modelos para que Sequelize los registre antes del sync()

require('./Usuario');
require('./Direccion');
require('./Vendedor');
require('./Repartidor');
require('./Producto');
require('./Pedido');
require('./DetallePedido');
require('./PasswordResetCode');
require('./Notificacion');

module.exports = {};
