import { deployContract } from "./utils";


export default async function () {
  const contractArtifactName = "MyAccount";
  await deployContract(contractArtifactName);
}
