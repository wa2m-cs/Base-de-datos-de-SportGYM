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
   TABLAS
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
    Contrasena NVARCHAR(255) NOT NULL, -- guardar el hash, no la contraseña en texto plano
    Telefono NVARCHAR(25) NULL,
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
    DireccionEntrega NVARCHAR(300) NOT NULL,
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
   ÍNDICES
   ========================= */

CREATE INDEX IX_Producto_IdCategoria
ON Producto(IdCategoria);
GO

CREATE INDEX IX_VarianteProducto_IdProducto
ON VarianteProducto(IdProducto);
GO

CREATE INDEX IX_Pedido_IdCliente_FechaPedido
ON Pedido(IdCliente, FechaPedido);
GO

CREATE INDEX IX_DetallePedido_IdPedido
ON DetallePedido(IdPedido);
GO

CREATE INDEX IX_Entrega_IdRepartidor_Estado
ON Entrega(IdRepartidor, EstadoEntrega);
GO


/* =========================
   TRIGGERS
   ========================= */

-- Ajusta el stock cuando se agrega, modifica o elimina un detalle del pedido.
CREATE TRIGGER trg_DetallePedido_ActualizarStock
ON DetallePedido
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH Insertados AS (
        SELECT IdVariante, SUM(Cantidad) AS CantidadNueva
        FROM inserted
        GROUP BY IdVariante
    ),
    Eliminados AS (
        SELECT IdVariante, SUM(Cantidad) AS CantidadAnterior
        FROM deleted
        GROUP BY IdVariante
    ),
    Cambios AS (
        SELECT
            COALESCE(i.IdVariante, e.IdVariante) AS IdVariante,
            ISNULL(i.CantidadNueva, 0) - ISNULL(e.CantidadAnterior, 0) AS Diferencia
        FROM Insertados i
        FULL OUTER JOIN Eliminados e
            ON i.IdVariante = e.IdVariante
    )
    IF EXISTS (
        SELECT 1
        FROM Cambios c
        INNER JOIN VarianteProducto v
            ON v.IdVariante = c.IdVariante
        WHERE c.Diferencia > v.Stock
    )
    BEGIN
        THROW 50001, 'No hay stock suficiente para realizar la operación.', 1;
    END;

    ;WITH Insertados AS (
        SELECT IdVariante, SUM(Cantidad) AS CantidadNueva
        FROM inserted
        GROUP BY IdVariante
    ),
    Eliminados AS (
        SELECT IdVariante, SUM(Cantidad) AS CantidadAnterior
        FROM deleted
        GROUP BY IdVariante
    ),
    Cambios AS (
        SELECT
            COALESCE(i.IdVariante, e.IdVariante) AS IdVariante,
            ISNULL(i.CantidadNueva, 0) - ISNULL(e.CantidadAnterior, 0) AS Diferencia
        FROM Insertados i
        FULL OUTER JOIN Eliminados e
            ON i.IdVariante = e.IdVariante
    )
    UPDATE v
    SET v.Stock = v.Stock - c.Diferencia
    FROM VarianteProducto v
    INNER JOIN Cambios c
        ON c.IdVariante = v.IdVariante;
END
GO


-- Recalcula el subtotal del pedido después de modificar sus detalles.
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


-- Resumen general de pedidos con pago y entrega.
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


-- Muestra las variantes que ya llegaron al nivel mínimo de stock.
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


/* =========================
   PROCEDIMIENTOS ALMACENADOS
   ========================= */

-- Crea un pedido para un usuario con rol Cliente.
CREATE PROCEDURE sp_CrearPedido
    @IdCliente INT,
    @CostoEnvio DECIMAL(10,2) = 0,
    @IdPedido INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (
        SELECT 1
        FROM Usuario u
        INNER JOIN Rol r ON r.IdRol = u.IdRol
        WHERE u.IdUsuario = @IdCliente
          AND r.Nombre = 'Cliente'
          AND u.Estado = 1
    )
    BEGIN
        THROW 50002, 'El usuario indicado no es un cliente activo.', 1;
    END;

    INSERT INTO Pedido (CostoEnvio, IdCliente)
    VALUES (@CostoEnvio, @IdCliente);

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
        THROW 50003, 'La cantidad debe ser mayor que cero.', 1;
    END;

    IF NOT EXISTS (
        SELECT 1
        FROM Pedido
        WHERE IdPedido = @IdPedido
          AND Estado NOT IN ('Cancelado', 'Entregado')
    )
    BEGIN
        THROW 50004, 'El pedido no existe o ya no puede modificarse.', 1;
    END;

    SELECT @Precio = p.Precio
    FROM VarianteProducto v
    INNER JOIN Producto p
        ON p.IdProducto = v.IdProducto
    WHERE v.IdVariante = @IdVariante
      AND p.Estado = 1;

    IF @Precio IS NULL
    BEGIN
        THROW 50005, 'La variante indicada no está disponible.', 1;
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


-- Registra un único pago por pedido tomando el total actual.
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
    WHERE IdPedido = @IdPedido;

    IF @Total IS NULL
    BEGIN
        THROW 50006, 'El pedido indicado no existe.', 1;
    END;

    IF @Total <= 0
    BEGIN
        THROW 50007, 'El pedido no tiene productos para pagar.', 1;
    END;

    IF EXISTS (
        SELECT 1
        FROM Pago
        WHERE IdPedido = @IdPedido
    )
    BEGIN
        THROW 50008, 'Este pedido ya tiene un pago registrado.', 1;
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


-- Asigna un pedido a un usuario con rol Repartidor.
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
          AND Estado <> 'Cancelado'
    )
    BEGIN
        THROW 50009, 'El pedido indicado no está disponible para entrega.', 1;
    END;

    IF EXISTS (
        SELECT 1
        FROM Entrega
        WHERE IdPedido = @IdPedido
    )
    BEGIN
        THROW 50010, 'El pedido ya tiene una entrega asignada.', 1;
    END;

    IF NOT EXISTS (
        SELECT 1
        FROM Usuario u
        INNER JOIN Rol r
            ON r.IdRol = u.IdRol
        WHERE u.IdUsuario = @IdRepartidor
          AND r.Nombre = 'Repartidor'
          AND u.Estado = 1
    )
    BEGIN
        THROW 50011, 'El usuario indicado no es un repartidor activo.', 1;
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
