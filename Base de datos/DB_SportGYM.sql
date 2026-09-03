/* =========================================================
   Base de datos - Tienda de ropa deportiva y gimnasio
   SQL Server
   ========================================================= */

IF DB_ID('SportFitStoreDB') IS NULL
BEGIN
    CREATE DATABASE SportFitStoreDB;
END
GO

USE SportFitStoreDB;
GO


/* =========================
   TABLAS PRINCIPALES
   ========================= */

CREATE TABLE Rol (
    IdRol INT IDENTITY(1,1) PRIMARY KEY,
    Nombre NVARCHAR(50) NOT NULL UNIQUE,
    Descripcion NVARCHAR(200) NULL
);
GO

CREATE TABLE Usuario (
    IdUsuario INT IDENTITY(1,1) PRIMARY KEY,
    Nombre NVARCHAR(80) NOT NULL,
    Apellido NVARCHAR(80) NOT NULL,
    Correo NVARCHAR(150) NOT NULL UNIQUE,
    Contrasena NVARCHAR(255) NOT NULL, -- guardar hash, no texto plano
    Telefono NVARCHAR(25) NULL,
   FechaNacimiento DATE NULL,
    Estado BIT NOT NULL CONSTRAINT DF_Usuario_Estado DEFAULT 1,
    FechaRegistro DATETIME2 NOT NULL CONSTRAINT DF_Usuario_FechaRegistro DEFAULT SYSDATETIME(),
    IdRol INT NOT NULL,

    CONSTRAINT FK_Usuario_Rol
        FOREIGN KEY (IdRol) REFERENCES Rol(IdRol)
);
GO

CREATE TABLE Categoria (
    IdCategoria INT IDENTITY(1,1) PRIMARY KEY,
    Nombre NVARCHAR(100) NOT NULL UNIQUE,
    Descripcion NVARCHAR(250) NULL,
    Estado BIT NOT NULL CONSTRAINT DF_Categoria_Estado DEFAULT 1
);
GO

CREATE TABLE Producto (
    IdProducto INT IDENTITY(1,1) PRIMARY KEY,
    Nombre NVARCHAR(120) NOT NULL,
    Descripcion NVARCHAR(500) NULL,
    Precio DECIMAL(10,2) NOT NULL,
    Marca NVARCHAR(100) NULL,
    Genero NVARCHAR(20) NULL,
    Imagen NVARCHAR(500) NULL,
    Estado BIT NOT NULL CONSTRAINT DF_Producto_Estado DEFAULT 1,
    IdCategoria INT NOT NULL,

    CONSTRAINT CK_Producto_Precio CHECK (Precio >= 0),
    CONSTRAINT CK_Producto_Genero
        CHECK (Genero IS NULL OR Genero IN ('Hombre', 'Mujer', 'Unisex')),

    CONSTRAINT FK_Producto_Categoria
        FOREIGN KEY (IdCategoria) REFERENCES Categoria(IdCategoria)
);
GO

CREATE TABLE VarianteProducto (
    IdVariante INT IDENTITY(1,1) PRIMARY KEY,
    Talla NVARCHAR(20) NOT NULL,
    Color NVARCHAR(50) NOT NULL,
    SKU NVARCHAR(60) NOT NULL UNIQUE,
    Stock INT NOT NULL CONSTRAINT DF_VarianteProducto_Stock DEFAULT 0,
    StockMinimo INT NOT NULL CONSTRAINT DF_VarianteProducto_StockMinimo DEFAULT 3,
    IdProducto INT NOT NULL,

    CONSTRAINT CK_VarianteProducto_Stock CHECK (Stock >= 0),
    CONSTRAINT CK_VarianteProducto_StockMinimo CHECK (StockMinimo >= 0),

    CONSTRAINT FK_VarianteProducto_Producto
        FOREIGN KEY (IdProducto) REFERENCES Producto(IdProducto)
);
GO

CREATE TABLE Pedido (
    IdPedido INT IDENTITY(1,1) PRIMARY KEY,
    FechaPedido DATETIME2 NOT NULL CONSTRAINT DF_Pedido_FechaPedido DEFAULT SYSDATETIME(),
    Estado NVARCHAR(30) NOT NULL CONSTRAINT DF_Pedido_Estado DEFAULT 'Pendiente',
    Subtotal DECIMAL(10,2) NOT NULL CONSTRAINT DF_Pedido_Subtotal DEFAULT 0,
    CostoEnvio DECIMAL(10,2) NOT NULL CONSTRAINT DF_Pedido_CostoEnvio DEFAULT 0,
   DireccionEntrega VARCHAR(300) NOT NULL,
    Total AS (Subtotal + CostoEnvio) PERSISTED,
    IdCliente INT NOT NULL,

    CONSTRAINT CK_Pedido_Subtotal CHECK (Subtotal >= 0),
    CONSTRAINT CK_Pedido_CostoEnvio CHECK (CostoEnvio >= 0),
    CONSTRAINT CK_Pedido_Estado CHECK (
        Estado IN (
            'Pendiente',
            'Confirmado',
            'Preparando',
            'Listo',
            'Enviado',
            'Entregado',
            'Cancelado'
        )
    ),

    CONSTRAINT FK_Pedido_Cliente
        FOREIGN KEY (IdCliente) REFERENCES Usuario(IdUsuario)
);
GO

CREATE TABLE DetallePedido (
    IdDetalle INT IDENTITY(1,1) PRIMARY KEY,
    Cantidad INT NOT NULL,
    PrecioUnitario DECIMAL(10,2) NOT NULL,
    Subtotal AS (Cantidad * PrecioUnitario) PERSISTED,
    IdPedido INT NOT NULL,
    IdVariante INT NOT NULL,

    CONSTRAINT CK_DetallePedido_Cantidad CHECK (Cantidad > 0),
    CONSTRAINT CK_DetallePedido_Precio CHECK (PrecioUnitario >= 0),

    CONSTRAINT FK_DetallePedido_Pedido
        FOREIGN KEY (IdPedido) REFERENCES Pedido(IdPedido),

    CONSTRAINT FK_DetallePedido_Variante
        FOREIGN KEY (IdVariante) REFERENCES VarianteProducto(IdVariante)
);
GO

CREATE TABLE Pago (
    IdPago INT IDENTITY(1,1) PRIMARY KEY,
    FechaPago DATETIME2 NOT NULL CONSTRAINT DF_Pago_FechaPago DEFAULT SYSDATETIME(),
    Monto DECIMAL(10,2) NOT NULL,
    MetodoPago NVARCHAR(40) NOT NULL,
    EstadoPago NVARCHAR(30) NOT NULL CONSTRAINT DF_Pago_Estado DEFAULT 'Pendiente',
    Referencia NVARCHAR(100) NULL,
    IdPedido INT NOT NULL UNIQUE,

    CONSTRAINT CK_Pago_Monto CHECK (Monto >= 0),
    CONSTRAINT CK_Pago_Estado CHECK (
        EstadoPago IN ('Pendiente', 'Aprobado', 'Rechazado', 'Reembolsado')
    ),

    CONSTRAINT FK_Pago_Pedido
        FOREIGN KEY (IdPedido) REFERENCES Pedido(IdPedido)
);
GO

CREATE TABLE Entrega (
    IdEntrega INT IDENTITY(1,1) PRIMARY KEY,
    FechaAsignacion DATETIME2 NOT NULL CONSTRAINT DF_Entrega_FechaAsignacion DEFAULT SYSDATETIME(),
    FechaEntrega DATETIME2 NULL,
    EstadoEntrega NVARCHAR(30) NOT NULL CONSTRAINT DF_Entrega_Estado DEFAULT 'Asignada',
    Observaciones NVARCHAR(500) NULL,
    IdPedido INT NOT NULL UNIQUE,
    IdRepartidor INT NOT NULL,

    CONSTRAINT CK_Entrega_Estado CHECK (
        EstadoEntrega IN ('Asignada', 'En camino', 'Entregada', 'No entregada')
    ),

    CONSTRAINT FK_Entrega_Pedido
        FOREIGN KEY (IdPedido) REFERENCES Pedido(IdPedido),

    CONSTRAINT FK_Entrega_Repartidor
        FOREIGN KEY (IdRepartidor) REFERENCES Usuario(IdUsuario)
);
GO


/* =========================
   TABLA DE AUDITORÍA
   ========================= */

CREATE TABLE Auditoria (
    IdAuditoria BIGINT IDENTITY(1,1) PRIMARY KEY,
    TablaAfectada NVARCHAR(60) NOT NULL,
    IdRegistro INT NULL,
    Accion NVARCHAR(10) NOT NULL,
    ValorAnterior NVARCHAR(MAX) NULL,
    ValorNuevo NVARCHAR(MAX) NULL,
    FechaCambio DATETIME2 NOT NULL CONSTRAINT DF_Auditoria_Fecha DEFAULT SYSDATETIME(),
    IdUsuarioAccion INT NULL,
    UsuarioBD SYSNAME NOT NULL CONSTRAINT DF_Auditoria_UsuarioBD DEFAULT ORIGINAL_LOGIN(),

    CONSTRAINT CK_Auditoria_Accion
        CHECK (Accion IN ('INSERT', 'UPDATE', 'DELETE'))
);
GO


/* =========================
   DATOS INICIALES
   ========================= */

INSERT INTO Rol (Nombre, Descripcion)
VALUES
('Cliente', 'Usuario que realiza compras'),
('Empleado', 'Personal que prepara pedidos y gestiona productos'),
('Administrador', 'Usuario con acceso administrativo'),
('Repartidor', 'Usuario encargado de realizar entregas');
GO


/* =========================
   TRIGGERS DE FUNCIONAMIENTO
   ========================= */

-- Ajusta el stock al agregar, cambiar o quitar productos de un pedido.
CREATE TRIGGER trg_DetallePedido_ActualizarStock
ON DetallePedido
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Cambios TABLE (
        IdVariante INT PRIMARY KEY,
        Diferencia INT NOT NULL
    );

    INSERT INTO @Cambios (IdVariante, Diferencia)
    SELECT
        IdVariante,
        SUM(Diferencia)
    FROM (
        SELECT IdVariante, Cantidad AS Diferencia
        FROM inserted

        UNION ALL

        SELECT IdVariante, -Cantidad AS Diferencia
        FROM deleted
    ) AS Movimientos
    GROUP BY IdVariante;

    IF EXISTS (
        SELECT 1
        FROM @Cambios c
        INNER JOIN VarianteProducto v
            ON v.IdVariante = c.IdVariante
        WHERE c.Diferencia > v.Stock
    )
    BEGIN
        THROW 50001, 'No hay stock suficiente para realizar la operación.', 1;
    END;

    UPDATE v
    SET v.Stock = v.Stock - c.Diferencia
    FROM VarianteProducto v
    INNER JOIN @Cambios c
        ON c.IdVariante = v.IdVariante;
END
GO


-- Mantiene actualizado el subtotal del pedido.
CREATE TRIGGER trg_DetallePedido_RecalcularPedido
ON DetallePedido
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH PedidosAfectados AS (
        SELECT IdPedido FROM inserted
        UNION
        SELECT IdPedido FROM deleted
    )
    UPDATE p
    SET p.Subtotal = ISNULL((
        SELECT SUM(d.Subtotal)
        FROM DetallePedido d
        WHERE d.IdPedido = p.IdPedido
    ), 0)
    FROM Pedido p
    INNER JOIN PedidosAfectados pa
        ON pa.IdPedido = p.IdPedido;
END
GO


/* =========================
   TRIGGERS DE AUDITORÍA
   ========================= */

-- Registra altas, cambios y bajas de roles.
CREATE TRIGGER trg_Rol_Auditoria
ON Rol
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @IdUsuarioAccion INT = TRY_CONVERT(INT, SESSION_CONTEXT(N'IdUsuario'));

    IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO Auditoria (TablaAfectada, IdRegistro, Accion, ValorAnterior, ValorNuevo, IdUsuarioAccion)
        SELECT
            'Rol',
            i.IdRol,
            'UPDATE',
            CONCAT('Nombre=', d.Nombre, '; Descripcion=', ISNULL(d.Descripcion,'')),
            CONCAT('Nombre=', i.Nombre, '; Descripcion=', ISNULL(i.Descripcion,'')),
            @IdUsuarioAccion
        FROM inserted i
        INNER JOIN deleted d ON d.IdRol = i.IdRol;
    END
    ELSE IF EXISTS (SELECT 1 FROM inserted)
    BEGIN
        INSERT INTO Auditoria (TablaAfectada, IdRegistro, Accion, ValorNuevo, IdUsuarioAccion)
        SELECT
            'Rol',
            i.IdRol,
            'INSERT',
            CONCAT('Nombre=', i.Nombre, '; Descripcion=', ISNULL(i.Descripcion,'')),
            @IdUsuarioAccion
        FROM inserted i;
    END
    ELSE
    BEGIN
        INSERT INTO Auditoria (TablaAfectada, IdRegistro, Accion, ValorAnterior, IdUsuarioAccion)
        SELECT
            'Rol',
            d.IdRol,
            'DELETE',
            CONCAT('Nombre=', d.Nombre, '; Descripcion=', ISNULL(d.Descripcion,'')),
            @IdUsuarioAccion
        FROM deleted d;
    END
END
GO


-- Registra altas, cambios y bajas de usuarios.
CREATE TRIGGER trg_Usuario_Auditoria
ON Usuario
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @IdUsuarioAccion INT = TRY_CONVERT(INT, SESSION_CONTEXT(N'IdUsuario'));

    IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO Auditoria (TablaAfectada, IdRegistro, Accion, ValorAnterior, ValorNuevo, IdUsuarioAccion)
        SELECT
            'Usuario',
            i.IdUsuario,
            'UPDATE',
            CONCAT('Nombre=', d.Nombre, '; Apellido=', d.Apellido, '; Correo=', d.Correo,
                   '; Telefono=', ISNULL(d.Telefono,''), '; Estado=', d.Estado, '; IdRol=', d.IdRol),
            CONCAT('Nombre=', i.Nombre, '; Apellido=', i.Apellido, '; Correo=', i.Correo,
                   '; Telefono=', ISNULL(i.Telefono,''), '; Estado=', i.Estado, '; IdRol=', i.IdRol),
            @IdUsuarioAccion
        FROM inserted i
        INNER JOIN deleted d ON d.IdUsuario = i.IdUsuario;
    END
    ELSE IF EXISTS (SELECT 1 FROM inserted)
    BEGIN
        INSERT INTO Auditoria (TablaAfectada, IdRegistro, Accion, ValorNuevo, IdUsuarioAccion)
        SELECT
            'Usuario',
            i.IdUsuario,
            'INSERT',
            CONCAT('Nombre=', i.Nombre, '; Apellido=', i.Apellido, '; Correo=', i.Correo,
                   '; Telefono=', ISNULL(i.Telefono,''), '; Estado=', i.Estado, '; IdRol=', i.IdRol),
            @IdUsuarioAccion
        FROM inserted i;
    END
    ELSE
    BEGIN
        INSERT INTO Auditoria (TablaAfectada, IdRegistro, Accion, ValorAnterior, IdUsuarioAccion)
        SELECT
            'Usuario',
            d.IdUsuario,
            'DELETE',
            CONCAT('Nombre=', d.Nombre, '; Apellido=', d.Apellido, '; Correo=', d.Correo,
                   '; Telefono=', ISNULL(d.Telefono,''), '; Estado=', d.Estado, '; IdRol=', d.IdRol),
            @IdUsuarioAccion
        FROM deleted d;
    END
END
GO


-- Registra altas, cambios y bajas de categorías.
CREATE TRIGGER trg_Categoria_Auditoria
ON Categoria
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @IdUsuarioAccion INT = TRY_CONVERT(INT, SESSION_CONTEXT(N'IdUsuario'));

    IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO Auditoria (TablaAfectada, IdRegistro, Accion, ValorAnterior, ValorNuevo, IdUsuarioAccion)
        SELECT
            'Categoria',
            i.IdCategoria,
            'UPDATE',
            CONCAT('Nombre=', d.Nombre, '; Descripcion=', ISNULL(d.Descripcion,''), '; Estado=', d.Estado),
            CONCAT('Nombre=', i.Nombre, '; Descripcion=', ISNULL(i.Descripcion,''), '; Estado=', i.Estado),
            @IdUsuarioAccion
        FROM inserted i
        INNER JOIN deleted d ON d.IdCategoria = i.IdCategoria;
    END
    ELSE IF EXISTS (SELECT 1 FROM inserted)
    BEGIN
        INSERT INTO Auditoria (TablaAfectada, IdRegistro, Accion, ValorNuevo, IdUsuarioAccion)
        SELECT
            'Categoria',
            i.IdCategoria,
            'INSERT',
            CONCAT('Nombre=', i.Nombre, '; Descripcion=', ISNULL(i.Descripcion,''), '; Estado=', i.Estado),
            @IdUsuarioAccion
        FROM inserted i;
    END
    ELSE
    BEGIN
        INSERT INTO Auditoria (TablaAfectada, IdRegistro, Accion, ValorAnterior, IdUsuarioAccion)
        SELECT
            'Categoria',
            d.IdCategoria,
            'DELETE',
            CONCAT('Nombre=', d.Nombre, '; Descripcion=', ISNULL(d.Descripcion,''), '; Estado=', d.Estado),
            @IdUsuarioAccion
        FROM deleted d;
    END
END
GO


-- Registra altas, cambios y bajas de productos.
CREATE TRIGGER trg_Producto_Auditoria
ON Producto
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @IdUsuarioAccion INT = TRY_CONVERT(INT, SESSION_CONTEXT(N'IdUsuario'));

    IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO Auditoria (TablaAfectada, IdRegistro, Accion, ValorAnterior, ValorNuevo, IdUsuarioAccion)
        SELECT
            'Producto',
            i.IdProducto,
            'UPDATE',
            CONCAT('Nombre=', d.Nombre, '; Precio=', d.Precio, '; Marca=', ISNULL(d.Marca,''),
                   '; Genero=', ISNULL(d.Genero,''), '; Estado=', d.Estado, '; IdCategoria=', d.IdCategoria),
            CONCAT('Nombre=', i.Nombre, '; Precio=', i.Precio, '; Marca=', ISNULL(i.Marca,''),
                   '; Genero=', ISNULL(i.Genero,''), '; Estado=', i.Estado, '; IdCategoria=', i.IdCategoria),
            @IdUsuarioAccion
        FROM inserted i
        INNER JOIN deleted d ON d.IdProducto = i.IdProducto;
    END
    ELSE IF EXISTS (SELECT 1 FROM inserted)
    BEGIN
        INSERT INTO Auditoria (TablaAfectada, IdRegistro, Accion, ValorNuevo, IdUsuarioAccion)
        SELECT
            'Producto',
            i.IdProducto,
            'INSERT',
            CONCAT('Nombre=', i.Nombre, '; Precio=', i.Precio, '; Marca=', ISNULL(i.Marca,''),
                   '; Genero=', ISNULL(i.Genero,''), '; Estado=', i.Estado, '; IdCategoria=', i.IdCategoria),
            @IdUsuarioAccion
        FROM inserted i;
    END
    ELSE
    BEGIN
        INSERT INTO Auditoria (TablaAfectada, IdRegistro, Accion, ValorAnterior, IdUsuarioAccion)
        SELECT
            'Producto',
            d.IdProducto,
            'DELETE',
            CONCAT('Nombre=', d.Nombre, '; Precio=', d.Precio, '; Marca=', ISNULL(d.Marca,''),
                   '; Genero=', ISNULL(d.Genero,''), '; Estado=', d.Estado, '; IdCategoria=', d.IdCategoria),
            @IdUsuarioAccion
        FROM deleted d;
    END
END
GO


-- Registra cambios de talla, color, SKU y stock.
CREATE TRIGGER trg_VarianteProducto_Auditoria
ON VarianteProducto
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @IdUsuarioAccion INT = TRY_CONVERT(INT, SESSION_CONTEXT(N'IdUsuario'));

    IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO Auditoria (TablaAfectada, IdRegistro, Accion, ValorAnterior, ValorNuevo, IdUsuarioAccion)
        SELECT
            'VarianteProducto',
            i.IdVariante,
            'UPDATE',
            CONCAT('Talla=', d.Talla, '; Color=', d.Color, '; SKU=', d.SKU,
                   '; Stock=', d.Stock, '; StockMinimo=', d.StockMinimo, '; IdProducto=', d.IdProducto),
            CONCAT('Talla=', i.Talla, '; Color=', i.Color, '; SKU=', i.SKU,
                   '; Stock=', i.Stock, '; StockMinimo=', i.StockMinimo, '; IdProducto=', i.IdProducto),
            @IdUsuarioAccion
        FROM inserted i
        INNER JOIN deleted d ON d.IdVariante = i.IdVariante;
    END
    ELSE IF EXISTS (SELECT 1 FROM inserted)
    BEGIN
        INSERT INTO Auditoria (TablaAfectada, IdRegistro, Accion, ValorNuevo, IdUsuarioAccion)
        SELECT
            'VarianteProducto',
            i.IdVariante,
            'INSERT',
            CONCAT('Talla=', i.Talla, '; Color=', i.Color, '; SKU=', i.SKU,
                   '; Stock=', i.Stock, '; StockMinimo=', i.StockMinimo, '; IdProducto=', i.IdProducto),
            @IdUsuarioAccion
        FROM inserted i;
    END
    ELSE
    BEGIN
        INSERT INTO Auditoria (TablaAfectada, IdRegistro, Accion, ValorAnterior, IdUsuarioAccion)
        SELECT
            'VarianteProducto',
            d.IdVariante,
            'DELETE',
            CONCAT('Talla=', d.Talla, '; Color=', d.Color, '; SKU=', d.SKU,
                   '; Stock=', d.Stock, '; StockMinimo=', d.StockMinimo, '; IdProducto=', d.IdProducto),
            @IdUsuarioAccion
        FROM deleted d;
    END
END
GO


-- Registra altas, cambios y bajas de pedidos.
CREATE TRIGGER trg_Pedido_Auditoria
ON Pedido
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @IdUsuarioAccion INT = TRY_CONVERT(INT, SESSION_CONTEXT(N'IdUsuario'));

    IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO Auditoria (TablaAfectada, IdRegistro, Accion, ValorAnterior, ValorNuevo, IdUsuarioAccion)
        SELECT
            'Pedido',
            i.IdPedido,
            'UPDATE',
            CONCAT('Estado=', d.Estado, '; Subtotal=', d.Subtotal, '; CostoEnvio=', d.CostoEnvio,
                   '; IdCliente=', d.IdCliente),
            CONCAT('Estado=', i.Estado, '; Subtotal=', i.Subtotal, '; CostoEnvio=', i.CostoEnvio,
                   '; IdCliente=', i.IdCliente),
            @IdUsuarioAccion
        FROM inserted i
        INNER JOIN deleted d ON d.IdPedido = i.IdPedido;
    END
    ELSE IF EXISTS (SELECT 1 FROM inserted)
    BEGIN
        INSERT INTO Auditoria (TablaAfectada, IdRegistro, Accion, ValorNuevo, IdUsuarioAccion)
        SELECT
            'Pedido',
            i.IdPedido,
            'INSERT',
            CONCAT('Estado=', i.Estado, '; Subtotal=', i.Subtotal, '; CostoEnvio=', i.CostoEnvio,
                   '; IdCliente=', i.IdCliente),
            @IdUsuarioAccion
        FROM inserted i;
    END
    ELSE
    BEGIN
        INSERT INTO Auditoria (TablaAfectada, IdRegistro, Accion, ValorAnterior, IdUsuarioAccion)
        SELECT
            'Pedido',
            d.IdPedido,
            'DELETE',
            CONCAT('Estado=', d.Estado, '; Subtotal=', d.Subtotal, '; CostoEnvio=', d.CostoEnvio,
                   '; IdCliente=', d.IdCliente),
            @IdUsuarioAccion
        FROM deleted d;
    END
END
GO


-- Registra cambios en los productos incluidos en cada pedido.
CREATE TRIGGER trg_DetallePedido_Auditoria
ON DetallePedido
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @IdUsuarioAccion INT = TRY_CONVERT(INT, SESSION_CONTEXT(N'IdUsuario'));

    IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO Auditoria (TablaAfectada, IdRegistro, Accion, ValorAnterior, ValorNuevo, IdUsuarioAccion)
        SELECT
            'DetallePedido',
            i.IdDetalle,
            'UPDATE',
            CONCAT('Cantidad=', d.Cantidad, '; PrecioUnitario=', d.PrecioUnitario,
                   '; IdPedido=', d.IdPedido, '; IdVariante=', d.IdVariante),
            CONCAT('Cantidad=', i.Cantidad, '; PrecioUnitario=', i.PrecioUnitario,
                   '; IdPedido=', i.IdPedido, '; IdVariante=', i.IdVariante),
            @IdUsuarioAccion
        FROM inserted i
        INNER JOIN deleted d ON d.IdDetalle = i.IdDetalle;
    END
    ELSE IF EXISTS (SELECT 1 FROM inserted)
    BEGIN
        INSERT INTO Auditoria (TablaAfectada, IdRegistro, Accion, ValorNuevo, IdUsuarioAccion)
        SELECT
            'DetallePedido',
            i.IdDetalle,
            'INSERT',
            CONCAT('Cantidad=', i.Cantidad, '; PrecioUnitario=', i.PrecioUnitario,
                   '; IdPedido=', i.IdPedido, '; IdVariante=', i.IdVariante),
            @IdUsuarioAccion
        FROM inserted i;
    END
    ELSE
    BEGIN
        INSERT INTO Auditoria (TablaAfectada, IdRegistro, Accion, ValorAnterior, IdUsuarioAccion)
        SELECT
            'DetallePedido',
            d.IdDetalle,
            'DELETE',
            CONCAT('Cantidad=', d.Cantidad, '; PrecioUnitario=', d.PrecioUnitario,
                   '; IdPedido=', d.IdPedido, '; IdVariante=', d.IdVariante),
            @IdUsuarioAccion
        FROM deleted d;
    END
END
GO


-- Registra altas, cambios y bajas de pagos.
CREATE TRIGGER trg_Pago_Auditoria
ON Pago
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @IdUsuarioAccion INT = TRY_CONVERT(INT, SESSION_CONTEXT(N'IdUsuario'));

    IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO Auditoria (TablaAfectada, IdRegistro, Accion, ValorAnterior, ValorNuevo, IdUsuarioAccion)
        SELECT
            'Pago',
            i.IdPago,
            'UPDATE',
            CONCAT('Monto=', d.Monto, '; MetodoPago=', d.MetodoPago, '; EstadoPago=', d.EstadoPago,
                   '; Referencia=', ISNULL(d.Referencia,''), '; IdPedido=', d.IdPedido),
            CONCAT('Monto=', i.Monto, '; MetodoPago=', i.MetodoPago, '; EstadoPago=', i.EstadoPago,
                   '; Referencia=', ISNULL(i.Referencia,''), '; IdPedido=', i.IdPedido),
            @IdUsuarioAccion
        FROM inserted i
        INNER JOIN deleted d ON d.IdPago = i.IdPago;
    END
    ELSE IF EXISTS (SELECT 1 FROM inserted)
    BEGIN
        INSERT INTO Auditoria (TablaAfectada, IdRegistro, Accion, ValorNuevo, IdUsuarioAccion)
        SELECT
            'Pago',
            i.IdPago,
            'INSERT',
            CONCAT('Monto=', i.Monto, '; MetodoPago=', i.MetodoPago, '; EstadoPago=', i.EstadoPago,
                   '; Referencia=', ISNULL(i.Referencia,''), '; IdPedido=', i.IdPedido),
            @IdUsuarioAccion
        FROM inserted i;
    END
    ELSE
    BEGIN
        INSERT INTO Auditoria (TablaAfectada, IdRegistro, Accion, ValorAnterior, IdUsuarioAccion)
        SELECT
            'Pago',
            d.IdPago,
            'DELETE',
            CONCAT('Monto=', d.Monto, '; MetodoPago=', d.MetodoPago, '; EstadoPago=', d.EstadoPago,
                   '; Referencia=', ISNULL(d.Referencia,''), '; IdPedido=', d.IdPedido),
            @IdUsuarioAccion
        FROM deleted d;
    END
END
GO


-- Registra altas, cambios y bajas de entregas.
CREATE TRIGGER trg_Entrega_Auditoria
ON Entrega
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @IdUsuarioAccion INT = TRY_CONVERT(INT, SESSION_CONTEXT(N'IdUsuario'));

    IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO Auditoria (TablaAfectada, IdRegistro, Accion, ValorAnterior, ValorNuevo, IdUsuarioAccion)
        SELECT
            'Entrega',
            i.IdEntrega,
            'UPDATE',
            CONCAT('Direccion=', d.DireccionEntrega, '; Estado=', d.EstadoEntrega,
                   '; FechaEntrega=', ISNULL(CONVERT(NVARCHAR(30), d.FechaEntrega, 126),''),
                   '; IdPedido=', d.IdPedido, '; IdRepartidor=', d.IdRepartidor),
            CONCAT('Direccion=', i.DireccionEntrega, '; Estado=', i.EstadoEntrega,
                   '; FechaEntrega=', ISNULL(CONVERT(NVARCHAR(30), i.FechaEntrega, 126),''),
                   '; IdPedido=', i.IdPedido, '; IdRepartidor=', i.IdRepartidor),
            @IdUsuarioAccion
        FROM inserted i
        INNER JOIN deleted d ON d.IdEntrega = i.IdEntrega;
    END
    ELSE IF EXISTS (SELECT 1 FROM inserted)
    BEGIN
        INSERT INTO Auditoria (TablaAfectada, IdRegistro, Accion, ValorNuevo, IdUsuarioAccion)
        SELECT
            'Entrega',
            i.IdEntrega,
            'INSERT',
            CONCAT('Direccion=', i.DireccionEntrega, '; Estado=', i.EstadoEntrega,
                   '; FechaEntrega=', ISNULL(CONVERT(NVARCHAR(30), i.FechaEntrega, 126),''),
                   '; IdPedido=', i.IdPedido, '; IdRepartidor=', i.IdRepartidor),
            @IdUsuarioAccion
        FROM inserted i;
    END
    ELSE
    BEGIN
        INSERT INTO Auditoria (TablaAfectada, IdRegistro, Accion, ValorAnterior, IdUsuarioAccion)
        SELECT
            'Entrega',
            d.IdEntrega,
            'DELETE',
            CONCAT('Direccion=', d.DireccionEntrega, '; Estado=', d.EstadoEntrega,
                   '; FechaEntrega=', ISNULL(CONVERT(NVARCHAR(30), d.FechaEntrega, 126),''),
                   '; IdPedido=', d.IdPedido, '; IdRepartidor=', d.IdRepartidor),
            @IdUsuarioAccion
        FROM deleted d;
    END
END
GO


/* =========================
   VISTAS
   ========================= */

-- Catálogo con producto, variante y stock disponible.
CREATE VIEW vw_CatalogoProductos
AS
SELECT
    p.IdProducto,
    p.Nombre AS Producto,
    p.Descripcion,
    p.Precio,
    p.Marca,
    p.Genero,
    p.Imagen,
    c.Nombre AS Categoria,
    v.IdVariante,
    v.Talla,
    v.Color,
    v.SKU,
    v.Stock
FROM Producto p
INNER JOIN Categoria c
    ON c.IdCategoria = p.IdCategoria
INNER JOIN VarianteProducto v
    ON v.IdProducto = p.IdProducto
WHERE p.Estado = 1
  AND c.Estado = 1;
GO


-- Resumen de pedidos con estado de pago y entrega.
CREATE VIEW vw_ResumenPedidos
AS
SELECT
    p.IdPedido,
    p.FechaPedido,
    CONCAT(u.Nombre, ' ', u.Apellido) AS Cliente,
    u.Correo,
    p.Estado AS EstadoPedido,
    p.Subtotal,
    p.CostoEnvio,
    p.Total,
    ISNULL(pg.EstadoPago, 'Sin pago') AS EstadoPago,
    ISNULL(pg.MetodoPago, 'Sin registrar') AS MetodoPago,
    ISNULL(e.EstadoEntrega, 'Sin entrega') AS EstadoEntrega
FROM Pedido p
INNER JOIN Usuario u
    ON u.IdUsuario = p.IdCliente
LEFT JOIN Pago pg
    ON pg.IdPedido = p.IdPedido
LEFT JOIN Entrega e
    ON e.IdPedido = p.IdPedido;
GO


-- Variantes que llegaron al nivel mínimo de stock.
CREATE VIEW vw_StockBajo
AS
SELECT
    v.IdVariante,
    p.Nombre AS Producto,
    v.Talla,
    v.Color,
    v.SKU,
    v.Stock,
    v.StockMinimo
FROM VarianteProducto v
INNER JOIN Producto p
    ON p.IdProducto = v.IdProducto
WHERE v.Stock <= v.StockMinimo;
GO


-- Historial de cambios más fácil de consultar.
CREATE VIEW vw_HistorialAuditoria
AS
SELECT
    IdAuditoria,
    TablaAfectada,
    IdRegistro,
    Accion,
    ValorAnterior,
    ValorNuevo,
    FechaCambio,
    IdUsuarioAccion,
    UsuarioBD
FROM Auditoria;
GO


/* =========================
   PROCEDIMIENTOS ALMACENADOS
   ========================= */

-- Crea un pedido para un cliente activo.
CREATE PROCEDURE sp_CrearPedido
    @IdCliente INT,
    @CostoEnvio DECIMAL(10,2) = 0,
    @DireccionEntrega VARCHAR(300),
    @IdPedido INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF @CostoEnvio < 0
    BEGIN
        THROW 50002, 'El costo de envío no puede ser negativo.', 1;
    END;

    IF @DireccionEntrega IS NULL
       OR LTRIM(RTRIM(@DireccionEntrega)) = ''
    BEGIN
        THROW 50004, 'La dirección de entrega es obligatoria.', 1;
    END;

    IF NOT EXISTS (
        SELECT 1
        FROM Usuario u
        INNER JOIN Rol r ON r.IdRol = u.IdRol
        WHERE u.IdUsuario = @IdCliente
          AND r.Nombre = 'Cliente'
          AND u.Estado = 1
    )
    BEGIN
        THROW 50003, 'El usuario indicado no es un cliente activo.', 1;
    END;

    INSERT INTO Pedido (
        CostoEnvio,
        DireccionEntrega,
        IdCliente
    )
    VALUES (
        @CostoEnvio,
        @DireccionEntrega,
        @IdCliente
    );

    SET @IdPedido = SCOPE_IDENTITY();
END
GO


-- Agrega una variante al pedido usando el precio actual del producto.
CREATE PROCEDURE sp_AgregarDetallePedido
    @IdPedido INT,
    @IdVariante INT,
    @Cantidad INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Precio DECIMAL(10,2);

    IF @Cantidad <= 0
    BEGIN
        THROW 50004, 'La cantidad debe ser mayor que cero.', 1;
    END;

    IF NOT EXISTS (
        SELECT 1
        FROM Pedido
        WHERE IdPedido = @IdPedido
          AND Estado IN ('Pendiente', 'Confirmado')
    )
    BEGIN
        THROW 50005, 'El pedido no existe o ya no puede modificarse.', 1;
    END;

    SELECT @Precio = p.Precio
    FROM VarianteProducto v
    INNER JOIN Producto p
        ON p.IdProducto = v.IdProducto
    WHERE v.IdVariante = @IdVariante
      AND p.Estado = 1;

    IF @Precio IS NULL
    BEGIN
        THROW 50006, 'La variante indicada no está disponible.', 1;
    END;

    INSERT INTO DetallePedido (
        Cantidad,
        PrecioUnitario,
        IdPedido,
        IdVariante
    )
    VALUES (
        @Cantidad,
        @Precio,
        @IdPedido,
        @IdVariante
    );
END
GO


-- Registra el pago único del pedido tomando su total actual.
CREATE PROCEDURE sp_RegistrarPago
    @IdPedido INT,
    @MetodoPago NVARCHAR(40),
    @Referencia NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Total DECIMAL(10,2);

    SELECT @Total = Total
    FROM Pedido
    WHERE IdPedido = @IdPedido
      AND Estado <> 'Cancelado';

    IF @Total IS NULL
    BEGIN
        THROW 50007, 'El pedido indicado no existe o está cancelado.', 1;
    END;

    IF @Total <= 0
    BEGIN
        THROW 50008, 'El pedido no tiene productos para pagar.', 1;
    END;

    IF EXISTS (
        SELECT 1
        FROM Pago
        WHERE IdPedido = @IdPedido
    )
    BEGIN
        THROW 50009, 'Este pedido ya tiene un pago registrado.', 1;
    END;

    INSERT INTO Pago (
        Monto,
        MetodoPago,
        EstadoPago,
        Referencia,
        IdPedido
    )
    VALUES (
        @Total,
        @MetodoPago,
        'Aprobado',
        @Referencia,
        @IdPedido
    );

    UPDATE Pedido
    SET Estado = 'Confirmado'
    WHERE IdPedido = @IdPedido
      AND Estado = 'Pendiente';
END
GO


-- Asigna un pedido a un repartidor activo.
CREATE PROCEDURE sp_AsignarEntrega
    @IdPedido INT,
    @IdRepartidor INT,
    @DireccionEntrega NVARCHAR(300),
    @Observaciones NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (
        SELECT 1
        FROM Pedido
        WHERE IdPedido = @IdPedido
          AND Estado NOT IN ('Cancelado', 'Entregado')
    )
    BEGIN
        THROW 50010, 'El pedido indicado no está disponible para entrega.', 1;
    END;

    IF EXISTS (
        SELECT 1
        FROM Entrega
        WHERE IdPedido = @IdPedido
    )
    BEGIN
        THROW 50011, 'El pedido ya tiene una entrega asignada.', 1;
    END;

    IF NOT EXISTS (
        SELECT 1
        FROM Usuario u
        INNER JOIN Rol r ON r.IdRol = u.IdRol
        WHERE u.IdUsuario = @IdRepartidor
          AND r.Nombre = 'Repartidor'
          AND u.Estado = 1
    )
    BEGIN
        THROW 50012, 'El usuario indicado no es un repartidor activo.', 1;
    END;

    INSERT INTO Entrega (
        DireccionEntrega,
        EstadoEntrega,
        Observaciones,
        IdPedido,
        IdRepartidor
    )
    VALUES (
        @DireccionEntrega,
        'Asignada',
        @Observaciones,
        @IdPedido,
        @IdRepartidor
    );
END
GO


-- Permite identificar en auditoría al usuario de la aplicación.
CREATE PROCEDURE sp_EstablecerUsuarioAuditoria
    @IdUsuario INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Usuario WHERE IdUsuario = @IdUsuario)
    BEGIN
        THROW 50013, 'El usuario indicado no existe.', 1;
    END;

    EXEC sys.sp_set_session_context
        @key = N'IdUsuario',
        @value = @IdUsuario;
END
GO
