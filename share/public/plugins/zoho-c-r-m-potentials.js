(function () {
	'use strict';

	var valueMap = {
		'Potential Name': 'name',
		'Stage':          'stage',
		'Closing Date':   'closingDate'
	};

	angular.module('StatusDashboard').directive('zohoCrmPotentials', [
		'statusService', 'moment',
		function (statusService, moment) {
			return {
				restrict:    'E',
				link:        function (scope, element, attrs) {
					var allPotentials = [];
					scope.stages = [];
					scope.$watch(function () {
						return statusService.getStatus(scope.statusId)
					}, function (newValue, oldValue) {
						if (newValue === null) {
							return;
						}
						allPotentials = newValue.map(function (potential) {
							var result = {};
							potential.FL.forEach(function (property) {
								switch (property.val) {
									case 'Probability':
										result['probability'] = parseInt(property.content, 10);
										break;
									default:
										var key = valueMap[property.val];
										if (key) {
											result[key] = property.content;
										}
										break;
								}
							});
							result['closingDateInPast'] = moment().isAfter(result.closingDate);
							return result;
						});
					});
					scope.$watch('stagesStr', function (newValue, oldValue) {
						scope.stages = scope.$eval(newValue);
					});
					scope.potentials = function () {
						return allPotentials.filter(function (potential) {
							return scope.stages.indexOf(potential.stage) >= 0;
						});
					};
				},
				replace:     false,
				templateUrl: 'plugins/templates/zoho-crm-potentials.html',
				scope:       {
					statusId:      '@statusId',
					statusTitle:   '@statusTitle',
					stagesStr:     '@stages',
					count:         '@count',
					dateFormat:    '@dateFormat'
				}
			}
		}
	]);
}());
