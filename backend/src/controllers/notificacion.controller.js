const Notificacion = require('../models/Notificacion');

class NotificacionController {
  // Listar notificaciones del usuario (incluye las creadas para ese usuario)
  async listar(req, res) {
    try {
      const usuarioId = req.usuario.id;
      const notificaciones = await Notificacion.findAll({
        where: { usuarioId },
        order: [['createdAt', 'DESC']],
      });
      return res.json({ notificaciones });
    } catch (error) {
      console.error('Error listar notificaciones:', error);
      return res.status(500).json({ error: 'Error al obtener notificaciones' });
    }
  }

  // Marcar como leída
  async marcarLeida(req, res) {
    try {
      const { id } = req.params;
      const usuarioId = req.usuario.id;

      const n = await Notificacion.findByPk(id);
      if (!n) return res.status(404).json({ error: 'Notificación no encontrada' });
      if (n.usuarioId !== usuarioId) return res.status(403).json({ error: 'No autorizado' });

      await n.update({ leida: true });
      return res.json({ message: 'Marcada como leída' });
    } catch (error) {
      console.error('Error marcar leida:', error);
      return res.status(500).json({ error: 'Error al actualizar notificación' });
    }
  }
}

module.exports = new NotificacionController();
