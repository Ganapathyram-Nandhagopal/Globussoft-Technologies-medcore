-- Core Department / Material / Requisition migration.
-- Added after the original department feature was introduced
-- but before department-material holding/adjustment migrations.

-- Requisition/material movement types required by the later migrations.
ALTER TYPE "StockMovementType" ADD VALUE IF NOT EXISTS 'ISSUE';
ALTER TYPE "StockMovementType" ADD VALUE IF NOT EXISTS 'RECEIVE';
ALTER TYPE "StockMovementType" ADD VALUE IF NOT EXISTS 'TRANSFER';

-- Department
CREATE TABLE "departments" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "code" TEXT NOT NULL,
    "active" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "tenantId" TEXT,

    CONSTRAINT "departments_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "departments_tenantId_code_key"
ON "departments"("tenantId", "code");

CREATE INDEX "departments_tenantId_idx"
ON "departments"("tenantId");

ALTER TABLE "departments"
ADD CONSTRAINT "departments_tenantId_fkey"
FOREIGN KEY ("tenantId") REFERENCES "tenants"("id")
ON DELETE CASCADE ON UPDATE CASCADE;


-- Department members
CREATE TABLE "department_members" (
    "id" TEXT NOT NULL,
    "departmentId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "tenantId" TEXT,

    CONSTRAINT "department_members_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "department_members_departmentId_userId_key"
ON "department_members"("departmentId", "userId");

CREATE INDEX "department_members_tenantId_idx"
ON "department_members"("tenantId");

CREATE INDEX "department_members_userId_idx"
ON "department_members"("userId");

CREATE INDEX "department_members_departmentId_idx"
ON "department_members"("departmentId");

ALTER TABLE "department_members"
ADD CONSTRAINT "department_members_tenantId_fkey"
FOREIGN KEY ("tenantId") REFERENCES "tenants"("id")
ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "department_members"
ADD CONSTRAINT "department_members_departmentId_fkey"
FOREIGN KEY ("departmentId") REFERENCES "departments"("id")
ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "department_members"
ADD CONSTRAINT "department_members_userId_fkey"
FOREIGN KEY ("userId") REFERENCES "users"("id")
ON DELETE CASCADE ON UPDATE CASCADE;


-- Requisition status
CREATE TYPE "RequisitionStatus" AS ENUM (
    'DRAFT',
    'SUBMITTED',
    'PENDING_APPROVAL',
    'APPROVED',
    'REJECTED',
    'PARTIALLY_APPROVED',
    'READY_FOR_ISSUE',
    'PARTIALLY_ISSUED',
    'ISSUED',
    'RECEIVED',
    'COMPLETED',
    'CANCELLED'
);


-- Requisitions
CREATE TABLE "requisitions" (
    "id" TEXT NOT NULL,
    "requisitionNumber" TEXT NOT NULL,
    "departmentId" TEXT NOT NULL,
    "status" "RequisitionStatus" NOT NULL DEFAULT 'DRAFT',
    "notes" TEXT,
    "remarks" TEXT,
    "requestedById" TEXT NOT NULL,
    "approvedById" TEXT,
    "issuedById" TEXT,
    "receivedById" TEXT,
    "submittedAt" TIMESTAMP(3),
    "approvedAt" TIMESTAMP(3),
    "issuedAt" TIMESTAMP(3),
    "receivedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "tenantId" TEXT,

    CONSTRAINT "requisitions_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "requisitions_requisitionNumber_key"
ON "requisitions"("requisitionNumber");

CREATE INDEX "requisitions_departmentId_idx"
ON "requisitions"("departmentId");

CREATE INDEX "requisitions_status_idx"
ON "requisitions"("status");

CREATE INDEX "requisitions_tenantId_idx"
ON "requisitions"("tenantId");

ALTER TABLE "requisitions"
ADD CONSTRAINT "requisitions_tenantId_fkey"
FOREIGN KEY ("tenantId") REFERENCES "tenants"("id")
ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "requisitions"
ADD CONSTRAINT "requisitions_departmentId_fkey"
FOREIGN KEY ("departmentId") REFERENCES "departments"("id");

ALTER TABLE "requisitions"
ADD CONSTRAINT "requisitions_requestedById_fkey"
FOREIGN KEY ("requestedById") REFERENCES "users"("id");


-- Requisition items
CREATE TABLE "requisition_items" (
    "id" TEXT NOT NULL,
    "requisitionId" TEXT NOT NULL,
    "inventoryItemId" TEXT,
    "materialId" TEXT,
    "requestedQty" INTEGER NOT NULL,
    "approvedQty" INTEGER NOT NULL DEFAULT 0,
    "issuedQty" INTEGER NOT NULL DEFAULT 0,
    "receivedQty" INTEGER NOT NULL DEFAULT 0,
    "remarks" TEXT,
    "tenantId" TEXT,

    CONSTRAINT "requisition_items_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "requisition_items_requisitionId_idx"
ON "requisition_items"("requisitionId");

CREATE INDEX "requisition_items_inventoryItemId_idx"
ON "requisition_items"("inventoryItemId");

CREATE INDEX "requisition_items_materialId_idx"
ON "requisition_items"("materialId");

CREATE INDEX "requisition_items_tenantId_idx"
ON "requisition_items"("tenantId");

ALTER TABLE "requisition_items"
ADD CONSTRAINT "requisition_items_tenantId_fkey"
FOREIGN KEY ("tenantId") REFERENCES "tenants"("id")
ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "requisition_items"
ADD CONSTRAINT "requisition_items_requisitionId_fkey"
FOREIGN KEY ("requisitionId") REFERENCES "requisitions"("id")
ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "requisition_items"
ADD CONSTRAINT "requisition_items_inventoryItemId_fkey"
FOREIGN KEY ("inventoryItemId") REFERENCES "inventory_items"("id");




-- Material categories
CREATE TYPE "MaterialCategory" AS ENUM (
    'MEDICINE',
    'CONSUMABLE',
    'EQUIPMENT',
    'INSTRUMENT',
    'MACHINE'
);


-- Materials
CREATE TABLE "materials" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "sku" TEXT,
    "category" "MaterialCategory" NOT NULL DEFAULT 'CONSUMABLE',
    "unit" TEXT NOT NULL DEFAULT 'unit',
    "quantity" INTEGER NOT NULL DEFAULT 0,
    "reservedStock" INTEGER NOT NULL DEFAULT 0,
    "reorderLevel" INTEGER NOT NULL DEFAULT 10,
    "unitCost" DOUBLE PRECISION,
    "location" TEXT,
    "active" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "tenantId" TEXT,

    CONSTRAINT "materials_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "materials_tenantId_sku_key"
ON "materials"("tenantId", "sku");

CREATE INDEX "materials_tenantId_idx"
ON "materials"("tenantId");

CREATE INDEX "materials_category_idx"
ON "materials"("category");

ALTER TABLE "materials"
ADD CONSTRAINT "materials_tenantId_fkey"
FOREIGN KEY ("tenantId") REFERENCES "tenants"("id")
ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "requisition_items"
ADD CONSTRAINT "requisition_items_materialId_fkey"
FOREIGN KEY ("materialId") REFERENCES "materials"("id");


-- Material movement ledger
CREATE TABLE "material_movements" (
    "id" TEXT NOT NULL,
    "materialId" TEXT NOT NULL,
    "type" "StockMovementType" NOT NULL,
    "quantity" INTEGER NOT NULL,
    "referenceId" TEXT,
    "reason" TEXT,
    "performedBy" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "tenantId" TEXT,

    CONSTRAINT "material_movements_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "material_movements_materialId_idx"
ON "material_movements"("materialId");

CREATE INDEX "material_movements_tenantId_idx"
ON "material_movements"("tenantId");

ALTER TABLE "material_movements"
ADD CONSTRAINT "material_movements_tenantId_fkey"
FOREIGN KEY ("tenantId") REFERENCES "tenants"("id")
ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "material_movements"
ADD CONSTRAINT "material_movements_materialId_fkey"
FOREIGN KEY ("materialId") REFERENCES "materials"("id")
ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "material_movements"
ADD CONSTRAINT "material_movements_performedBy_fkey"
FOREIGN KEY ("performedBy") REFERENCES "users"("id");
