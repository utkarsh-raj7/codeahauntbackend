// Worker entry point — imports all BullMQ workers to start processing
import '../config/redis';
import './provision.job';
import './cleanup.job';
import './monitor.job';

console.log('[workers] All BullMQ workers started');
