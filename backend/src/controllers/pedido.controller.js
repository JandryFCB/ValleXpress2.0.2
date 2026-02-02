/* controllers/pedido.controller.js */

const Pedido = require('../models/Pedido');
const Usuario = require('../models/Usuario');
const Vendedor = require('../models/Vendedor');
const Repartidor = require('../models/Repartidor');
const DetallePedido = require('../models/DetallePedido');
const Producto = require('../models/Producto');
const { sequelize } = require('../config/database');

class PedidoController {
  async obtenerPorId(req, res) {
    try {
      const { id } = req.params;

      const pedido = await Pedido.findByPk(id, {
        include: [
          {
            model: Usuario,
            as: 'cliente',
            attributes: ['id', 'nombre', 'apellido', 'telefono', 'email'],
          },

          {
            model: Vendedor,
            as: 'vendedor',
            include: [
              {
                model: Usuario,
                as: 'usuario',
                attributes: ['id', 'nombre', 'apellido', 'telefono', 'email'],
              },
            ],
          },
          {
            model: Repartidor,
            as: 'repartidor',
            required: false,
            include: [
              {
                model: Usuario,
                as: 'usuario',
                attributes: ['id', 'nombre', 'apellido', 'telefono', 'email'],
              },
            ],
          },
          {
            model: DetallePedido,
            as: 'detalles',
            include: [
              {
                model: Producto,
                as: 'producto',
              },
            ],
          },
        ],
      });

      if (!pedido) {
        return res.status(404).json({ error: 'Pedido no encontrado' });
      }

      res.json(pedido);
    } catch (error) {
      console.error('❌ Error obtener pedido por ID:', error);
      res.status(500).json({ error: 'Error interno del servidor' });
    }
  }

  async crear(req, res) {
    const t = await sequelize.transaction();
    try {
      const { vendedorId, productos, metodoPago, notasCliente } = req.body;
      const clienteId = req.usuario.id;

      // 1) Validar stock con lock y calcular subtotal
      let subtotal = 0;
      const afectaciones = []; // { producto, cantidad }

      for (const item of productos) {
        const producto = await Producto.findByPk(item.productoId, {
          transaction: t,
          lock: true,
        });
        if (!producto) {
          await t.rollback();
          return res.status(404).json({ error: `Producto ${item.productoId} no encontrado` });
        }
        const cant = Number(item.cantidad) || 0;
        if (producto.stock < cant) {
          await t.rollback();
          return res.status(400).json({
            error: `Stock insuficiente para ${producto.nombre}`,
            disponible: producto.stock,
            solicitado: cant,
            productoId: producto.id,
            code: 'STOCK_INSUFICIENTE',
          });
        }
        subtotal += Number(producto.precio) * cant;
        afectaciones.push({ producto, cantidad: cant });
      }

      // 2) Crear pedido
      const pedido = await Pedido.create({
        clienteId,
        vendedorId,
        subtotal,
        costoDelivery: 0, // se asignará cuando el repartidor acepte
        total: subtotal,
        metodoPago,
        notasCliente,
      }, { transaction: t });

      // 3) Crear detalles y descontar stock
      for (const item of productos) {
        const producto = await Producto.findByPk(item.productoId, {
          transaction: t,
          lock: true,
        });
        const cant = Number(item.cantidad) || 0;

        await DetallePedido.create({
          pedidoId: pedido.id,
          productoId: producto.id,
          cantidad: cant,
          precioUnitario: producto.precio,
          subtotal: Number(producto.precio) * cant,
        }, { transaction: t });
      }

      // Descontar stock y desactivar si llega a 0
      for (const { producto, cantidad } of afectaciones) {
        const nuevoStock = Number(producto.stock) - Number(cantidad);
        producto.stock = nuevoStock;
        if (nuevoStock <= 0) {
          producto.disponible = false;
        }
        await producto.save({ transaction: t });
      }

      await t.commit();
      return res.status(201).json({ pedido });
    } catch (error) {
      await t.rollback();
      console.error('❌ Error crear pedido:', error);
      return res.status(500).json({ error: 'Error interno del servidor' });
    }
  }

  async misPedidos(req, res) {
    try {
      const clienteId = req.usuario.id;

      const pedidos = await Pedido.findAll({
        where: { clienteId },
        include: [
          {
            model: Vendedor,
            as: 'vendedor',
            include: [
              {
                model: Usuario,
                as: 'usuario',
                attributes: ['id', 'nombre', 'apellido', 'telefono', 'email'],
              },
            ],
          },
          {
            model: Repartidor,
            as: 'repartidor',
            required: false,
            include: [
              {
                model: Usuario,
                as: 'usuario',
                attributes: ['id', 'nombre', 'apellido', 'telefono', 'email'],
              },
            ],
          },
          {
            model: DetallePedido,
            as: 'detalles',
            include: [
              {
                model: Producto,
                as: 'producto',
              },
            ],
          },
        ],
        order: [['fechaPedido', 'DESC']],
      });

      res.json(pedidos);
    } catch (error) {
      console.error('❌ Error obtener mis pedidos:', error);
      res.status(500).json({ error: 'Error interno del servidor' });
    }
  }

  async pedidosVendedor(req, res) {
    try {
      const usuarioId = req.usuario.id;

      const vendedor = await Vendedor.findOne({
        where: { usuarioId },
        attributes: ['id'],
      });

      if (!vendedor) {
        return res.status(404).json({ error: 'Vendedor no encontrado' });
      }

      const pedidos = await Pedido.findAll({
        where: { vendedorId: vendedor.id },
        include: [
          {
            model: Usuario,
            as: 'cliente',
            attributes: ['id', 'nombre', 'apellido', 'telefono', 'email'],
          },
          {
            model: Repartidor,
            as: 'repartidor',
            required: false,
            include: [
              {
                model: Usuario,
                as: 'usuario',
                attributes: ['id', 'nombre', 'apellido', 'telefono', 'email'],
              },
            ],
          },
          {
            model: DetallePedido,
            as: 'detalles',
            include: [
              {
                model: Producto,
                as: 'producto',
              },
            ],
          },
        ],
        order: [['fechaPedido', 'DESC']],
      });

      res.json(pedidos);
    } catch (error) {
      console.error('❌ Error obtener pedidos vendedor:', error);
      res.status(500).json({ error: 'Error interno del servidor' });
    }
  }

  async actualizarEstado(req, res) {
    try {
      const { id } = req.params;
      const { estado } = req.body;
      const usuarioId = req.usuario.id;

      const vendedor = await Vendedor.findOne({
        where: { usuarioId },
        attributes: ['id'],
      });

      if (!vendedor) {
        return res.status(404).json({ error: 'Vendedor no encontrado' });
      }

      const pedido = await Pedido.findOne({
        where: { id, vendedorId: vendedor.id },
      });

      if (!pedido) {
        return res.status(404).json({ error: 'Pedido no encontrado' });
      }

      const fechaCampo = {
        confirmado: 'fechaConfirmacion',
        preparando: 'fechaPreparacion',
        listo: 'fechaListo',
      }[estado];

      await pedido.update({
        estado,
        [fechaCampo]: new Date(),
      });

      res.json(pedido);
    } catch (error) {
      console.error('❌ Error actualizar estado:', error);
      res.status(500).json({ error: 'Error interno del servidor' });
    }
  }

  async cancelar(req, res) {
    const t = await sequelize.transaction();
    try {
      const { id } = req.params;
      const clienteId = req.usuario.id;

      const pedido = await Pedido.findOne({
        where: { id, clienteId },
        transaction: t,
        lock: true,
      });

      if (!pedido) {
        await t.rollback();
        return res.status(404).json({ error: 'Pedido no encontrado' });
      }

      if (pedido.estado !== 'pendiente') {
        await t.rollback();
        return res.status(400).json({ error: 'No se puede cancelar un pedido que ya está en proceso' });
      }

      // Traer detalles del pedido
      const detalles = await DetallePedido.findAll({
        where: { pedidoId: pedido.id },
        transaction: t,
        lock: true,
      });

      // Reponer stock por cada detalle
      for (const d of detalles) {
        const producto = await Producto.findByPk(d.productoId, {
          transaction: t,
          lock: true,
        });
        if (!producto) continue;

        const nuevoStock = Number(producto.stock) + Number(d.cantidad);
        producto.stock = nuevoStock;
        // Si estaba en 0 y vuelve a >0, activar automáticamente
        if (nuevoStock > 0) {
          producto.disponible = true;
        }
        await producto.save({ transaction: t });
      }

      // Cambiar estado del pedido
      await pedido.update({ estado: 'cancelado' }, { transaction: t });

      await t.commit();
      return res.json({ message: 'Pedido cancelado exitosamente' });
    } catch (error) {
      await t.rollback();
      console.error('❌ Error cancelar pedido:', error);
      return res.status(500).json({ error: 'Error interno del servidor' });
    }
  }

  async marcarEnCamino(req, res) {
    try {
      const { id } = req.params;
      const usuarioId = req.usuario.id;

      const repartidor = await Repartidor.findOne({
        where: { usuarioId },
        attributes: ['id'],
      });

      if (!repartidor) {
        return res.status(404).json({ error: 'Repartidor no encontrado' });
      }

      const pedido = await Pedido.findOne({
        where: { id, repartidorId: repartidor.id },
      });

      if (!pedido) {
        return res.status(404).json({ error: 'Pedido no encontrado' });
      }

      if (pedido.estado !== 'listo') {
        return res.status(400).json({ error: 'El pedido debe estar listo para marcar en camino' });
      }

      await pedido.update({
        estado: 'en_camino',
        fechaRecogida: new Date(),
      });

      res.json({ message: 'Pedido marcado como en camino' });
    } catch (error) {
      console.error('❌ Error marcar en camino:', error);
      res.status(500).json({ error: 'Error interno del servidor' });
    }
  }

  async marcarEntregado(req, res) {
    try {
      const { id } = req.params;
      const usuarioId = req.usuario.id;

      const repartidor = await Repartidor.findOne({
        where: { usuarioId },
        attributes: ['id'],
      });

      if (!repartidor) {
        return res.status(404).json({ error: 'Repartidor no encontrado' });
      }

      const pedido = await Pedido.findOne({
        where: { id, repartidorId: repartidor.id },
      });

      if (!pedido) {
        return res.status(404).json({ error: 'Pedido no encontrado' });
      }

      if (pedido.estado !== 'en_camino') {
        return res.status(400).json({ error: 'El pedido debe estar en camino para marcar entregado' });
      }

      await pedido.update({
        estado: 'entregado',
        fechaEntrega: new Date(),
      });

      res.json({ message: 'Pedido marcado como entregado' });
    } catch (error) {
      console.error('❌ Error marcar entregado:', error);
      res.status(500).json({ error: 'Error interno del servidor' });
    }
  }

  async marcarRecibidoCliente(req, res) {
    try {
      const { id } = req.params;
      const clienteId = req.usuario.id;

      const pedido = await Pedido.findOne({
        where: { id, clienteId },
      });

      if (!pedido) {
        return res.status(404).json({ error: 'Pedido no encontrado' });
      }

      if (pedido.estado !== 'entregado') {
        return res.status(400).json({ error: 'El pedido debe estar entregado para marcar recibido' });
      }

      await pedido.update({ estado: 'recibido_cliente' });

      // devolver pedido actualizado para el frontend
      const pedidoActualizado = await Pedido.findByPk(pedido.id, {
        include: [
          {
            model: Usuario,
            as: 'cliente',
            attributes: ['id', 'nombre', 'apellido', 'telefono', 'email'],
          },
          {
            model: Vendedor,
            as: 'vendedor',
            include: [
              {
                model: Usuario,
                as: 'usuario',
                attributes: ['id', 'nombre', 'apellido', 'telefono', 'email'],
              },
            ],
          },
          {
            model: Repartidor,
            as: 'repartidor',
            required: false,
            include: [
              {
                model: Usuario,
                as: 'usuario',
                attributes: ['id', 'nombre', 'apellido', 'telefono', 'email'],
              },
            ],
          },
          {
            model: DetallePedido,
            as: 'detalles',
            include: [{ model: Producto, as: 'producto' }],
          },
        ],
      });

      res.json({ pedido: pedidoActualizado });
    } catch (error) {
      console.error('❌ Error marcar recibido cliente:', error);
      res.status(500).json({ error: 'Error interno del servidor' });
    }
  }

  async aceptarRepartidor(req, res) {
    try {
      const { id } = req.params;
      const { costoDelivery } = req.body;
      const usuarioId = req.usuario.id;

      const repartidor = await Repartidor.findOne({
        where: { usuarioId },
        attributes: ['id'],
      });

      if (!repartidor) {
        return res.status(404).json({ error: 'Repartidor no encontrado' });
      }

      const repartidorId = repartidor.id;

      const pedido = await Pedido.findByPk(id);

      if (!pedido) {
        return res.status(404).json({ error: 'Pedido no encontrado' });
      }

      if (pedido.repartidorId) {
        return res.status(400).json({ error: 'El pedido ya tiene un repartidor asignado' });
      }

      if (pedido.estado !== 'listo') {
        return res.status(400).json({ error: 'El pedido debe estar listo para asignar repartidor' });
      }

      const costoNum = Number(costoDelivery);
      const subtotalNum = Number(pedido.subtotal);
      if (!Number.isFinite(costoNum) || costoNum < 0) {
        return res.status(400).json({ error: 'Costo de delivery inválido' });
      }
      const totalNum = subtotalNum + costoNum;

      await pedido.update({
        repartidorId,
        costoDelivery: costoNum,
        total: totalNum,
        estado: 'en_camino',
        fechaRecogida: new Date(),
      });

      // devolver pedido actualizado para el frontend
      const pedidoActualizado = await Pedido.findByPk(pedido.id, {
        include: [
          {
            model: Usuario,
            as: 'cliente',
            attributes: ['id', 'nombre', 'apellido', 'telefono', 'email'],
          },
          {
            model: Vendedor,
            as: 'vendedor',
            include: [
              {
                model: Usuario,
                as: 'usuario',
                attributes: ['id', 'nombre', 'apellido', 'telefono', 'email'],
              },
            ],
          },
          {
            model: Repartidor,
            as: 'repartidor',
            required: false,
            include: [
              {
                model: Usuario,
                as: 'usuario',
                attributes: ['id', 'nombre', 'apellido', 'telefono', 'email'],
              },
            ],
          },
          {
            model: DetallePedido,
            as: 'detalles',
            include: [{ model: Producto, as: 'producto' }],
          },
        ],
      });

      res.json({ pedido: pedidoActualizado });
    } catch (error) {
      console.error('❌ Error aceptar repartidor:', error);
      res.status(500).json({ error: 'Error interno del servidor' });
    }
  }
}

module.exports = new PedidoController();
