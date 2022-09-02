import verifyContract from '../common/verifyContract';
import { passAddress as address, passArgs as args } from './config'

verifyContract(address, args)
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
