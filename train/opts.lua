--
--  Copyright (c) 2016, DMIS, Digital Mammography DREAM Challenge Team.
--  All rights reserved.
--
--  (Author) Bumsoo Kim, 2016
--  Github : https://github.com/meliketoy/DreamChallenge
--
--  Korea University, Data-Mining Lab
--  Digital Mammography DREAM Challenge Torch Implementation
--

local M = { }

function M.parse(arg)
   local cmd = torch.CmdLine()
   cmd:text()
   cmd:text('Torch-7 ResNet Training script')
   cmd:text('See https://github.com/facebook/fb.resnet.torch/blob/master/TRAINING.md for examples')
   cmd:text()
   cmd:text('Options:')
   -- General options ------------------------------------------------------------------------------------
   cmd:option('-data',       '/preprocessedData/dreamCh',         'Path to dataset')
   cmd:option('-dataset',    'dreamChallenge',           'Options: dreamChallenge')
   cmd:option('-manualSeed', 0,          'Manually set RNG seed')
   cmd:option('-nGPU',       2,          'Number of GPUs to use by default')
   cmd:option('-backend',    'cudnn',    'Options: cudnn | cunn')
   cmd:option('-cudnn',      'fastest',  'Options: fastest | default | deterministic')
   cmd:option('-gen',        'gen',      'Path to save generated files')

   -- Data options ---------------------------------------------------------------------------------------
   cmd:option('-nThreads',        16, 'number of data loading threads')
   
   -- Training options -----------------------------------------------------------------------------------
   cmd:option('-nEpochs',         0,       'Number of total epochs to run')
   cmd:option('-epochNumber',     1,       'Manual epoch number (useful on restarts)')
   cmd:option('-batchSize',       64,      'mini-batch size (1 = pure stochastic)')
   cmd:option('-tenCrop',         'false', 'Ten-crop testing')
   
   -- Checkpointing options ------------------------------------------------------------------------------
   cmd:option('-save',            '/modelState',    'Directory in which to save checkpoints')
   cmd:option('-resume',          '/modelState',    'Resume from the latest checkpoint in this directory')
   
   -- Optimization options -------------------------------------------------------------------------------
   cmd:option('-LR',              1e-3,       'initial learning rate')
   cmd:option('-momentum',        0.9,        'momentum')
   cmd:option('-weightDecay',     1e-3,       'weight decay')
   
   -- Model options --------------------------------------------------------------------------------------
   cmd:option('-netType',      'resnet',      'Options: resnet | preresnet | wide-resnet')
   cmd:option('-depth',        18,            'ResNet depth: 6n+4', 'number')
   cmd:option('-dropout',      0,             'Dropout rate')
   cmd:option('-shortcutType', '',            'Options: A | B | C')
   cmd:option('-retrain',      'none',        'fine-tuning, Path to model to retrain with')
   cmd:option('-optimState',   'none',        'Path to an optimState to reload from')
   
   -- Model options --------------------------------------------------------------------------------------
   cmd:option('-shareGradInput',  'false', 'Share gradInput tensors to reduce memory usage')
   cmd:option('-optnet',          'true',  'Use optnet to reduce memory usage')
   cmd:option('-resetClassifier', 'false', 'Reset the fully connected layer for fine-tuning')
   cmd:option('-nClasses',         0,      'Number of classes in the dataset')
   cmd:text()

   local opt = cmd:parse(arg or {})

   opt.saveLatest = opt.saveLatest ~= 'false'
   opt.tenCrop = opt.tenCrop ~= 'false'
   opt.shareGradInput = opt.shareGradInput ~= 'false'
   opt.optnet = opt.optnet ~= 'false'
   opt.resetClassifier = opt.resetClassifier ~= 'false'
   -- opt.nGPU = cutorch.getDeviceCount()
   
   opt.save = paths.concat(opt.save, opt.dataset, opt.netType, opt.depth)
   if opt.resume ~= 'none' then 
       opt.resume = paths.concat(opt.resume, opt.dataset, opt.netType, opt.depth)
   end

   if not paths.dirp(opt.save) and not paths.mkdir(opt.save) then
      cmd:error('error: unable to create checkpoint directory: ' .. opt.save .. '\n')
   end

   if not paths.dirp(opt.resume) and not paths.mkdir(opt.resume) then
      cmd:error('error: unable to create modelState directory: ' .. opt.save .. '\n')
   end

   if opt.dataset == 'dreamChallenge' then
      -- Handle the most common case of missing -data flag
      local trainDir = paths.concat(opt.data, 'train')
      -- if not paths.dirp(opt.data) then
      --   cmd:error('error: missing DreamChallengeNet data directory')
      -- elseif not paths.dirp(trainDir) then
      --   cmd:error('error: DreamChallengeNet missing `train` directory: ' .. trainDir)
      -- end
      -- Default shortcutType=B and nEpochs=40
      opt.shortcutType = opt.shortcutType == '' and 'B' or opt.shortcutType
      opt.nEpochs = opt.nEpochs == 0 and 40 or opt.nEpochs
      opt.imageSize = opt.imageSize == 0 and 224 or opt.imageSize
   else
      cmd:error('unknown dataset: ' .. opt.dataset)
   end

   if opt.resetClassifier then
      if opt.nClasses == 0 then
         cmd:error('-nClasses required when resetClassifier is set')
      end
   end

   if opt.shareGradInput and opt.optnet then
      cmd:error('error: cannot use both -shareGradInput and -optnet')
   end

   return opt
end

return M
