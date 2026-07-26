import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { after, afterEach, before, test } from "node:test";

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from "@firebase/rules-unit-testing";
import {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  setDoc,
  updateDoc,
  writeBatch,
} from "firebase/firestore";

const projectId = "demo-franalonso-rules";
const legacyRoots = ["prod", "dev", "backup"];
const legacyCollections = ["client", "sale", "service", "product"];
const deniedNewRoots = ["develop", "production"];

let testEnvironment;

before(async () => {
  const rules = await readFile(
    new URL("../firestore.rules", import.meta.url),
    "utf8",
  );

  testEnvironment = await initializeTestEnvironment({
    projectId,
    firestore: { rules },
  });
});

afterEach(async () => {
  await testEnvironment.clearFirestore();
});

after(async () => {
  await testEnvironment.cleanup();
});

for (const root of legacyRoots) {
  for (const collectionName of legacyCollections) {
    test(`allows unauthenticated legacy CRUD and list at ${root}/${root}/${collectionName}`, async () => {
      const firestore = testEnvironment.unauthenticatedContext().firestore();
      const collectionReference = collection(
        firestore,
        root,
        root,
        collectionName,
      );
      const documentReference = doc(collectionReference, "rules-test");

      await assertSucceeds(setDoc(documentReference, { revision: 1 }));
      await assertSucceeds(getDoc(documentReference));
      await assertSucceeds(updateDoc(documentReference, { revision: 2 }));
      await assertSucceeds(getDocs(collectionReference));
      await assertSucceeds(deleteDoc(documentReference));
    });
  }
}

test("allows the legacy backup-to-production incident flow", async () => {
  const firestore = testEnvironment.unauthenticatedContext().firestore();
  const backupReference = doc(
    firestore,
    "backup",
    "backup",
    "client",
    "incident-client",
  );
  const productionReference = doc(
    firestore,
    "prod",
    "prod",
    "client",
    "incident-client",
  );

  await assertSucceeds(setDoc(backupReference, { name: "Incident fixture" }));
  const backupSnapshot = await assertSucceeds(getDoc(backupReference));
  await assertSucceeds(setDoc(productionReference, backupSnapshot.data()));
});

for (const root of deniedNewRoots) {
  for (const context of ["unauthenticated", "authenticated"]) {
    test(`denies ${context} access to the new ${root} namespace`, async () => {
      const existingReferencePath = `${root}/collections/clients/existing-client`;

      await testEnvironment.withSecurityRulesDisabled(async (adminContext) => {
        await setDoc(doc(adminContext.firestore(), existingReferencePath), {
          revision: 1,
        });
      });

      const firestore = context === "authenticated"
        ? testEnvironment.authenticatedContext("rules-test-owner").firestore()
        : testEnvironment.unauthenticatedContext().firestore();
      const existingReference = doc(firestore, existingReferencePath);
      const newReference = doc(
        firestore,
        root,
        "collections",
        "clients",
        "new-client",
      );

      await assertFails(getDoc(existingReference));
      await assertFails(
        getDocs(collection(firestore, root, "collections", "clients")),
      );
      await assertFails(setDoc(newReference, { revision: 1 }));
      await assertFails(updateDoc(existingReference, { revision: 2 }));
      await assertFails(deleteDoc(existingReference));
    });
  }
}

for (const deniedPath of [
  "prod/dev/client/client-1",
  "dev/prod/client/client-1",
  "prod/prodX/client/client-1",
  "clientes/client-1",
  "visitas/visit-1",
]) {
  test(`denies the lookalike or obsolete path ${deniedPath}`, async () => {
    const firestore = testEnvironment.unauthenticatedContext().firestore();
    await assertFails(setDoc(doc(firestore, deniedPath), { value: true }));
  });
}

test("rejects an entire batch when any write targets a denied namespace", async () => {
  const clientFirestore = testEnvironment.unauthenticatedContext().firestore();
  const allowedReference = doc(
    clientFirestore,
    "prod",
    "prod",
    "client",
    "allowed-client",
  );
  const deniedReference = doc(
    clientFirestore,
    "production",
    "collections",
    "clients",
    "denied-client",
  );
  const batch = writeBatch(clientFirestore);
  batch.set(allowedReference, { value: "allowed" });
  batch.set(deniedReference, { value: "denied" });

  await assertFails(batch.commit());

  await testEnvironment.withSecurityRulesDisabled(async (adminContext) => {
    const snapshot = await getDoc(
      doc(
        adminContext.firestore(),
        "prod",
        "prod",
        "client",
        "allowed-client",
      ),
    );
    assert.equal(snapshot.exists(), false);
  });
});
